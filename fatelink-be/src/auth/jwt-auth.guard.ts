import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';
import { UsersService } from '../users/users.service';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private jwtService: JwtService,
    private usersService: UsersService, // Cần gọi xuống DB để check version
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const token = this.extractTokenFromHeader(request);
    
    if (!token) {
      throw new UnauthorizedException('Không tìm thấy Token xác thực. Vui lòng đăng nhập.');
    }
    
    try {
      const payload = await this.jwtService.verifyAsync(token, {
        secret: process.env.JWT_SECRET || 'fallback_secret',
      });

      // Kiểm tra Token Version trong Database
      // (Lưu ý: Thay thế hàm findById bằng hàm thực tế trong usersService của bạn)
      const user = await this.usersService.findById(payload.sub);
      if (!user || user.tokenVersion !== payload.tokenVersion) {
        throw new UnauthorizedException('Token đã bị thu hồi do đăng xuất ở thiết bị khác.');
      }

      // Gắn payload đã giải mã vào object request để Controller có thể truy xuất (req.user)
      request['user'] = payload;
    } catch {
      throw new UnauthorizedException('Token không hợp lệ hoặc đã hết hạn.');
    }
    return true;
  }

  private extractTokenFromHeader(request: Request): string | undefined {
    const [type, token] = request.headers.authorization?.split(' ') ?? [];
    return type === 'Bearer' ? token : undefined;
  }
}
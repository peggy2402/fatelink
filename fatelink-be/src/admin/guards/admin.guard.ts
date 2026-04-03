import { Injectable, CanActivate, ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class AdminGuard implements CanActivate {
  constructor(private jwtService: JwtService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Không tìm thấy token truy cập!');
    }

    const token = authHeader.split(' ')[1];
    try {
      // Giải mã và kiểm tra chữ ký JWT
      const payload = this.jwtService.verify(token, {
        secret: process.env.JWT_SECRET || 'fallback-secret-key',
      });
      
      request.user = payload; // Lưu thông tin Admin vào request
      return true;
    } catch (error) {
      throw new UnauthorizedException('Token không hợp lệ hoặc đã hết hạn!');
    }
  }
}
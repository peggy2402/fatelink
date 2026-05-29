import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';
import { UsersService } from '../../users/users.service';
import { AuthJwtPayload } from '../auth-jwt-payload.interface';
import { AUTH_ENV } from '../shared/auth.constants';

@Injectable()
export class LegacyJwtAuthGuard implements CanActivate {
  constructor(
    private readonly configService: ConfigService,
    private readonly jwtService: JwtService,
    private readonly usersService: UsersService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context
      .switchToHttp()
      .getRequest<Request & { user?: AuthJwtPayload }>();
    const token = this.extractTokenFromHeader(request);

    if (!token) {
      throw new UnauthorizedException(
        'Không tìm thấy Token xác thực. Vui lòng đăng nhập.',
      );
    }

    try {
      const payload = await this.jwtService.verifyAsync<AuthJwtPayload>(token, {
        secret: this.configService.getOrThrow<string>(AUTH_ENV.JWT_SECRET),
      });

      const user = await this.usersService.findById(payload.sub);
      if (!user || user.tokenVersion !== payload.tokenVersion) {
        throw new UnauthorizedException(
          'Token đã bị thu hồi do đăng xuất ở thiết bị khác.',
        );
      }

      request.user = payload;
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

import { Injectable, CanActivate, ExecutionContext, UnauthorizedException } from '@nestjs/common';

@Injectable()
export class AdminGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;

    // Kiểm tra xem header có chứa Token chuẩn của Admin không
    if (authHeader === 'Bearer admin-super-secret-token') {
      return true;
    }
    throw new UnauthorizedException('Không có quyền truy cập Admin!');
  }
}
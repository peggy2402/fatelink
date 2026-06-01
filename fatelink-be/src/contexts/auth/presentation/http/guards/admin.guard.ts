import {
  Injectable,
  CanActivate,
  ExecutionContext,
  Inject,
  UnauthorizedException,
} from '@nestjs/common';
import type { AuthenticatedUser } from '@shared/contracts/authenticated-user';
import type { ValidateAdminTokenUseCase } from '@contexts/auth/application/usecases/validate-admin-token.usecase';
import { AUTH_APPLICATION_TOKENS } from '@contexts/auth/composition/auth.tokens';
import type { Request } from 'express';

type AdminGuardRequest = Request & { user?: AuthenticatedUser };

@Injectable()
export class AdminGuard implements CanActivate {
  constructor(
    @Inject(AUTH_APPLICATION_TOKENS.validateAdminToken)
    private readonly validateAdminToken: ValidateAdminTokenUseCase,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AdminGuardRequest>();
    const authHeader = request.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Không tìm thấy token truy cập!');
    }

    const token = authHeader.split(' ')[1];
    try {
      const payload = await this.validateAdminToken.execute({ token });
      request.user = payload;
      return true;
    } catch {
      throw new UnauthorizedException('Token không hợp lệ hoặc đã hết hạn!');
    }
  }
}

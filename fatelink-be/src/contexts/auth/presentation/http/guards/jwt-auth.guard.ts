import {
  CanActivate,
  ExecutionContext,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import type { AuthenticatedUser } from '@shared/contracts/authenticated-user';
import type { ValidateUserTokenUseCase } from '@contexts/auth/application/usecases/validate-user-token.usecase';
import { AUTH_APPLICATION_TOKENS } from '@contexts/auth/composition/auth.tokens';
import type { Request } from 'express';

type GuardRequest = Request & { user?: AuthenticatedUser };

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    @Inject(AUTH_APPLICATION_TOKENS.validateUserToken)
    private readonly validateUserToken: ValidateUserTokenUseCase,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<GuardRequest>();
    const token = this.extractTokenFromHeader(request);

    if (!token) {
      throw new UnauthorizedException(
        'Không tìm thấy Token xác thực. Vui lòng đăng nhập.',
      );
    }

    try {
      const payload = await this.validateUserToken.execute({ token });
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

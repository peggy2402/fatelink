import { UnauthorizedApplicationError } from '@shared/errors/application-error';
import { ERROR_CODES } from '@shared/errors/error-codes';
import type { TokenService } from '@shared/contracts/token.service';

export class ValidateAdminTokenUseCase {
  constructor(private readonly tokenService: TokenService) {}

  async execute(input: { token: string }) {
    const payload = await this.tokenService.verifyAccessToken(input.token);
    if (payload.role !== 'admin') {
      throw new UnauthorizedApplicationError(
        'Token không có quyền admin.',
        ERROR_CODES.AUTH_ADMIN_TOKEN_FORBIDDEN,
      );
    }
    return payload;
  }
}

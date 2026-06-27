import type { AuthSessionRepository } from '@contexts/auth/domain/repositories/auth-session.repository';
import { UnauthorizedApplicationError } from '@shared/errors/application-error';
import { ERROR_CODES } from '@shared/errors/error-codes';
import type { TokenService } from '@shared/contracts/token.service';
import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';

export class ValidateUserTokenUseCase {
  constructor(
    private readonly authSessionRepository: AuthSessionRepository,
    private readonly tokenService: TokenService,
    private readonly userRepository: UserRepository,
  ) {}

  async execute(input: { token: string }) {
    const payload = await this.tokenService.verifyAccessToken(input.token);
    const user = await this.userRepository.findById(payload.sub);
    const session = payload.sessionId
      ? await this.authSessionRepository.findActiveBySessionId(
          payload.sessionId,
        )
      : null;

    if (!user || !session || session.userId !== user.id) {
      throw new UnauthorizedApplicationError(
        'Token đã bị thu hồi do đăng xuất ở thiết bị khác.',
        ERROR_CODES.AUTH_INVALID_ACCESS_TOKEN,
      );
    }

    await this.authSessionRepository.touch(session.sessionId);

    return payload;
  }
}

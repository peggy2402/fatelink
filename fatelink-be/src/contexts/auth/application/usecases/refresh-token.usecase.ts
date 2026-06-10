import type { AuthSessionContext } from '@contexts/auth/application/contracts/auth-session-context';
import type { AuthSessionRepository } from '@contexts/auth/domain/repositories/auth-session.repository';
import type { TokenService } from '@shared/contracts/token.service';
import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';
import { UnauthorizedApplicationError } from '@shared/errors/application-error';
import { ERROR_CODES } from '@shared/errors/error-codes';
import type { AuthSessionIssuer } from '@contexts/auth/application/services/auth-session-issuer.service';

export class RefreshTokenUseCase {
  constructor(
    private readonly authSessionRepository: AuthSessionRepository,
    private readonly tokenService: TokenService,
    private readonly userRepository: UserRepository,
    private readonly authSessionIssuer: AuthSessionIssuer,
  ) {}

  async execute(input: { refreshToken: string; context?: AuthSessionContext }) {
    const payload = await this.tokenService.verifyRefreshToken(
      input.refreshToken,
    );
    const user = await this.userRepository.findById(payload.sub);
    const session = await this.authSessionRepository.findActiveBySessionId(
      payload.sessionId,
    );

    if (
      !user ||
      !session ||
      session.userId !== user.id ||
      session.refreshTokenId !== payload.jti ||
      !input.context?.deviceId ||
      payload.deviceId !== input.context.deviceId ||
      session.deviceId !== input.context.deviceId
    ) {
      throw new UnauthorizedApplicationError(
        'Refresh token không hợp lệ hoặc đã hết hạn.',
        ERROR_CODES.AUTH_INVALID_REFRESH_TOKEN,
      );
    }

    return this.authSessionIssuer.issue({
      userId: user.id || '',
      deviceType: payload.deviceType || '',
      deviceId: payload.deviceId,
      currentSessionId: session.sessionId,
      currentRefreshTokenId: payload.jti,
      context: input.context,
    });
  }
}

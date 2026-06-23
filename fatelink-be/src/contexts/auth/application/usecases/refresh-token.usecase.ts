import type { AuthSessionContext } from '@contexts/auth/application/contracts/auth-session-context';
import type { AuthSessionRepository } from '@contexts/auth/domain/repositories/auth-session.repository';
import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';
import { UnauthorizedApplicationError } from '@shared/errors/application-error';
import { ERROR_CODES } from '@shared/errors/error-codes';
import type { AuthSessionIssuer } from '@contexts/auth/application/services/auth-session-issuer.service';
import { createHash } from 'crypto';

export class RefreshTokenUseCase {
  constructor(
    private readonly authSessionRepository: AuthSessionRepository,
    private readonly userRepository: UserRepository,
    private readonly authSessionIssuer: AuthSessionIssuer,
  ) {}

  async execute(input: { refreshToken: string; context?: AuthSessionContext }) {
    if (!input.context?.deviceId) {
      throw new UnauthorizedApplicationError(
        'Refresh token không hợp lệ hoặc đã hết hạn.',
        ERROR_CODES.AUTH_INVALID_REFRESH_TOKEN,
      );
    }

    const refreshTokenHash = this.hashRefreshToken(input.refreshToken);
    const session =
      await this.authSessionRepository.findActiveByRefreshTokenHash(
        refreshTokenHash,
      );
    const user = session
      ? await this.userRepository.findById(session.userId)
      : null;

    if (!user || !session || session.deviceId !== input.context.deviceId) {
      throw new UnauthorizedApplicationError(
        'Refresh token không hợp lệ hoặc đã hết hạn.',
        ERROR_CODES.AUTH_INVALID_REFRESH_TOKEN,
      );
    }

    return this.authSessionIssuer.issue({
      userId: user.id || '',
      deviceType: session.deviceType,
      deviceId: session.deviceId,
      currentSessionId: session.sessionId,
      currentRefreshToken: input.refreshToken,
      context: input.context,
    });
  }

  private hashRefreshToken(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }
}

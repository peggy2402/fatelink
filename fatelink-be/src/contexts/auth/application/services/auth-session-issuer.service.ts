import type { AuthSessionContext } from '@contexts/auth/application/contracts/auth-session-context';
import type { AuthSessionRepository } from '@contexts/auth/domain/repositories/auth-session.repository';
import type { TokenService } from '@shared/contracts/token.service';
import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';
import { InternalApplicationError } from '@shared/errors/application-error';
import { ERROR_CODES } from '@shared/errors/error-codes';
import { createHash, randomUUID } from 'crypto';

export class AuthSessionIssuer {
  constructor(
    private readonly authSessionRepository: AuthSessionRepository,
    private readonly userRepository: UserRepository,
    private readonly tokenService: TokenService,
  ) {}

  async issue(input: {
    userId: string;
    deviceType: string;
    deviceId: string;
    currentSessionId?: string;
    currentRefreshToken?: string;
    context?: AuthSessionContext;
  }) {
    const refreshToken = randomUUID();
    const refreshTokenHash = this.hashRefreshToken(refreshToken);
    const session = input.currentSessionId
      ? await this.authSessionRepository.rotate({
          currentSessionId: input.currentSessionId,
          currentRefreshTokenHash: this.hashRefreshToken(
            input.currentRefreshToken || '',
          ),
          nextRefreshTokenHash: refreshTokenHash,
          deviceType: input.deviceType,
          deviceId: input.deviceId,
          ipAddress: input.context?.ipAddress,
          userAgent: input.context?.userAgent,
        })
      : await this.authSessionRepository.create({
          sessionId: randomUUID(),
          userId: input.userId,
          deviceType: input.deviceType,
          deviceId: input.deviceId,
          refreshTokenHash,
          ipAddress: input.context?.ipAddress,
          userAgent: input.context?.userAgent,
        });
    const user = await this.userRepository.findById(input.userId);

    if (!user || !session) {
      throw new InternalApplicationError(
        'Không thể khởi tạo phiên đăng nhập.',
        ERROR_CODES.AUTH_SESSION_ISSUE_FAILED,
      );
    }

    return {
      user,
      accessToken: this.tokenService.signAccessToken({
        sub: input.userId,
        email: user.email,
        deviceType: input.deviceType,
        deviceId: input.deviceId,
        sessionId: session.sessionId,
      }),
      refreshToken,
    };
  }

  private hashRefreshToken(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }
}

import type { AuthSessionRepository } from '@contexts/auth/domain/repositories/auth-session.repository';
import {
  ForbiddenApplicationError,
  NotFoundApplicationError,
} from '@shared/errors/application-error';
import { ERROR_CODES } from '@shared/errors/error-codes';

export class RevokeAuthSessionUseCase {
  constructor(private readonly authSessionRepository: AuthSessionRepository) {}

  async execute(input: { userId: string; sessionId: string }) {
    const session = await this.authSessionRepository.findBySessionId(
      input.sessionId,
    );

    if (!session) {
      throw new NotFoundApplicationError(
        'Không tìm thấy phiên đăng nhập.',
        ERROR_CODES.AUTH_SESSION_NOT_FOUND,
      );
    }

    if (session.userId !== input.userId) {
      throw new ForbiddenApplicationError(
        'Bạn không có quyền thu hồi phiên đăng nhập này.',
        ERROR_CODES.AUTH_SESSION_REVOKE_FORBIDDEN,
      );
    }

    await this.authSessionRepository.revokeBySessionId(
      input.sessionId,
      'user_revoked',
    );

    return { message: 'Thu hồi phiên đăng nhập thành công.' };
  }
}

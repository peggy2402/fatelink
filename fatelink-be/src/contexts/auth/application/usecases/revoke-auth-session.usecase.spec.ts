import { RevokeAuthSessionUseCase } from './revoke-auth-session.usecase';
import {
  ForbiddenApplicationError,
  NotFoundApplicationError,
} from '@shared/errors/application-error';
import { AUTH_SESSION_STATUS } from '@contexts/auth/domain/repositories/auth-session.repository';

describe('RevokeAuthSessionUseCase', () => {
  it('revokes a session owned by the current user', async () => {
    const authSessionRepository = {
      findBySessionId: jest.fn().mockResolvedValue({
        sessionId: 'session-1',
        userId: 'user-1',
        deviceType: 'mobile',
        refreshTokenId: 'refresh-1',
        status: AUTH_SESSION_STATUS.ACTIVE,
        createdAt: new Date(),
        lastRefreshedAt: new Date(),
        lastSeenAt: new Date(),
      }),
      revokeBySessionId: jest.fn().mockResolvedValue(undefined),
    };

    const useCase = new RevokeAuthSessionUseCase(
      authSessionRepository as never,
    );
    const result = await useCase.execute({
      userId: 'user-1',
      sessionId: 'session-1',
    });

    expect(authSessionRepository.revokeBySessionId).toHaveBeenCalledWith(
      'session-1',
      'user_revoked',
    );
    expect(result).toEqual({
      message: 'Thu hồi phiên đăng nhập thành công.',
    });
  });

  it('fails when the session does not exist', async () => {
    const authSessionRepository = {
      findBySessionId: jest.fn().mockResolvedValue(null),
    };

    const useCase = new RevokeAuthSessionUseCase(
      authSessionRepository as never,
    );

    await expect(
      useCase.execute({ userId: 'user-1', sessionId: 'missing-session' }),
    ).rejects.toBeInstanceOf(NotFoundApplicationError);
  });

  it('fails when revoking another user session', async () => {
    const authSessionRepository = {
      findBySessionId: jest.fn().mockResolvedValue({
        sessionId: 'session-1',
        userId: 'user-2',
        deviceType: 'mobile',
        refreshTokenId: 'refresh-1',
        status: AUTH_SESSION_STATUS.ACTIVE,
        createdAt: new Date(),
        lastRefreshedAt: new Date(),
        lastSeenAt: new Date(),
      }),
    };

    const useCase = new RevokeAuthSessionUseCase(
      authSessionRepository as never,
    );

    await expect(
      useCase.execute({ userId: 'user-1', sessionId: 'session-1' }),
    ).rejects.toBeInstanceOf(ForbiddenApplicationError);
  });
});

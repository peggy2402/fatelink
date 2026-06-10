import { ListAuthSessionsUseCase } from './list-auth-sessions.usecase';
import { AUTH_SESSION_STATUS } from '@contexts/auth/domain/repositories/auth-session.repository';

describe('ListAuthSessionsUseCase', () => {
  it('marks the current session in the returned history', async () => {
    const authSessionRepository = {
      findByUserId: jest.fn().mockResolvedValue([
        {
          sessionId: 'current-session',
          userId: 'user-1',
          deviceType: 'mobile',
          refreshTokenId: 'refresh-1',
          status: AUTH_SESSION_STATUS.ACTIVE,
          createdAt: new Date(),
          lastRefreshedAt: new Date(),
          lastSeenAt: new Date(),
        },
        {
          sessionId: 'old-session',
          userId: 'user-1',
          deviceType: 'web',
          refreshTokenId: 'refresh-2',
          status: AUTH_SESSION_STATUS.ROTATED,
          createdAt: new Date(),
          lastRefreshedAt: new Date(),
          lastSeenAt: new Date(),
        },
      ]),
    };

    const useCase = new ListAuthSessionsUseCase(authSessionRepository as never);

    const result = await useCase.execute({
      userId: 'user-1',
      currentSessionId: 'current-session',
    });

    expect(authSessionRepository.findByUserId).toHaveBeenCalledWith('user-1');
    expect(result).toEqual([
      expect.objectContaining({
        sessionId: 'current-session',
        current: true,
      }),
      expect.objectContaining({
        sessionId: 'old-session',
        current: false,
      }),
    ]);
    expect(result[0]).not.toHaveProperty('refreshTokenId');
  });
});

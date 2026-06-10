import type { UnauthorizedApplicationError } from '@shared/errors/application-error';
import { ERROR_CODES } from '@shared/errors/error-codes';
import { ValidateUserTokenUseCase } from './validate-user-token.usecase';

describe('ValidateUserTokenUseCase', () => {
  it('returns the payload and touches the active session', async () => {
    const authSessionRepository = {
      findActiveBySessionId: jest.fn().mockResolvedValue({
        sessionId: 'session-1',
        userId: 'user-1',
      }),
      touch: jest.fn().mockResolvedValue(undefined),
    };
    const tokenService = {
      verifyAccessToken: jest.fn().mockResolvedValue({
        sub: 'user-1',
        sessionId: 'session-1',
      }),
    };
    const userRepository = {
      findById: jest.fn().mockResolvedValue({ id: 'user-1' }),
    };
    const useCase = new ValidateUserTokenUseCase(
      authSessionRepository as never,
      tokenService as never,
      userRepository as never,
    );

    const result = await useCase.execute({ token: 'access-token' });

    expect(authSessionRepository.touch).toHaveBeenCalledWith('session-1');
    expect(result).toEqual({ sub: 'user-1', sessionId: 'session-1' });
  });

  it('rejects when the session is no longer valid', async () => {
    const useCase = new ValidateUserTokenUseCase(
      {
        findActiveBySessionId: jest.fn().mockResolvedValue(null),
      } as never,
      {
        verifyAccessToken: jest.fn().mockResolvedValue({
          sub: 'user-1',
          sessionId: 'session-1',
        }),
      } as never,
      {
        findById: jest.fn().mockResolvedValue({ id: 'user-1' }),
      } as never,
    );

    await expect(
      useCase.execute({ token: 'access-token' }),
    ).rejects.toMatchObject<Partial<UnauthorizedApplicationError>>({
      errorCode: ERROR_CODES.AUTH_INVALID_ACCESS_TOKEN,
    });
  });
});

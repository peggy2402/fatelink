import type { UnauthorizedApplicationError } from '@shared/errors/application-error';
import { ERROR_CODES } from '@shared/errors/error-codes';
import { RefreshTokenUseCase } from './refresh-token.usecase';

describe('RefreshTokenUseCase', () => {
  it('rotates the current session through the session issuer', async () => {
    const authSessionRepository = {
      findActiveBySessionId: jest.fn().mockResolvedValue({
        sessionId: 'session-1',
        userId: 'user-1',
        deviceId: 'device-1',
        refreshTokenId: 'refresh-1',
      }),
    };
    const tokenService = {
      verifyRefreshToken: jest.fn().mockResolvedValue({
        sub: 'user-1',
        sessionId: 'session-1',
        jti: 'refresh-1',
        deviceType: 'mobile',
        deviceId: 'device-1',
      }),
    };
    const userRepository = {
      findById: jest.fn().mockResolvedValue({ id: 'user-1' }),
    };
    const authSessionIssuer = {
      issue: jest
        .fn()
        .mockResolvedValue({ accessToken: 'a', refreshToken: 'r' }),
    };
    const useCase = new RefreshTokenUseCase(
      authSessionRepository as never,
      tokenService as never,
      userRepository as never,
      authSessionIssuer as never,
    );

    await useCase.execute({
      refreshToken: 'refresh-token',
      context: { deviceId: 'device-1', ipAddress: '127.0.0.1' },
    });

    expect(authSessionIssuer.issue).toHaveBeenCalledWith({
      userId: 'user-1',
      deviceType: 'mobile',
      deviceId: 'device-1',
      currentSessionId: 'session-1',
      currentRefreshTokenId: 'refresh-1',
      context: { deviceId: 'device-1', ipAddress: '127.0.0.1' },
    });
  });

  it('rejects an invalid refresh token state', async () => {
    const useCase = new RefreshTokenUseCase(
      {
        findActiveBySessionId: jest.fn().mockResolvedValue(null),
      } as never,
      {
        verifyRefreshToken: jest.fn().mockResolvedValue({
          sub: 'user-1',
          sessionId: 'session-1',
          jti: 'refresh-1',
          deviceId: 'device-1',
        }),
      } as never,
      {
        findById: jest.fn().mockResolvedValue({ id: 'user-1' }),
      } as never,
      {} as never,
    );

    await expect(
      useCase.execute({
        refreshToken: 'refresh-token',
        context: { deviceId: 'different-device' },
      }),
    ).rejects.toMatchObject<Partial<UnauthorizedApplicationError>>({
      errorCode: ERROR_CODES.AUTH_INVALID_REFRESH_TOKEN,
    });
  });
});

import type { InternalApplicationError } from '@shared/errors/application-error';
import { ERROR_CODES } from '@shared/errors/error-codes';
import { AuthSessionIssuer } from './auth-session-issuer.service';

describe('AuthSessionIssuer', () => {
  it('creates a new session and signs token pair', async () => {
    const authSessionRepository = {
      create: jest.fn().mockResolvedValue({ sessionId: 'session-1' }),
    };
    const userRepository = {
      findById: jest.fn().mockResolvedValue({
        id: 'user-1',
        email: 'user@example.com',
      }),
    };
    const tokenService = {
      signAccessToken: jest.fn().mockReturnValue('access-token'),
    };
    const service = new AuthSessionIssuer(
      authSessionRepository as never,
      userRepository as never,
      tokenService as never,
    );

    const result = await service.issue({
      userId: 'user-1',
      deviceType: 'mobile',
      deviceId: 'device-1',
      context: { ipAddress: '127.0.0.1', userAgent: 'jest' },
    });

    expect(authSessionRepository.create).toHaveBeenCalledWith(
      expect.objectContaining({
        userId: 'user-1',
        deviceType: 'mobile',
        deviceId: 'device-1',
        ipAddress: '127.0.0.1',
        userAgent: 'jest',
      }),
    );
    expect(tokenService.signAccessToken).toHaveBeenCalledWith(
      expect.objectContaining({
        sub: 'user-1',
        deviceId: 'device-1',
        sessionId: 'session-1',
      }),
    );
    expect(result.refreshToken).toEqual(expect.any(String));
    expect(result.refreshToken).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i,
    );
  });

  it('reuses the same session during refresh rotation', async () => {
    const authSessionRepository = {
      rotate: jest.fn().mockResolvedValue({ sessionId: 'session-1' }),
    };
    const userRepository = {
      findById: jest.fn().mockResolvedValue({
        id: 'user-1',
        email: 'user@example.com',
      }),
    };
    const tokenService = {
      signAccessToken: jest.fn().mockReturnValue('access-token'),
    };
    const service = new AuthSessionIssuer(
      authSessionRepository as never,
      userRepository as never,
      tokenService as never,
    );

    await service.issue({
      userId: 'user-1',
      deviceType: 'mobile',
      deviceId: 'device-1',
      currentSessionId: 'session-1',
      currentRefreshToken: 'refresh-token-1',
      context: { ipAddress: '127.0.0.1' },
    });

    expect(authSessionRepository.rotate).toHaveBeenCalledWith(
      expect.objectContaining({
        currentSessionId: 'session-1',
        currentRefreshTokenHash: expect.any(String),
        nextRefreshTokenHash: expect.any(String),
        deviceType: 'mobile',
        deviceId: 'device-1',
        ipAddress: '127.0.0.1',
      }),
    );
    expect(tokenService.signAccessToken).toHaveBeenCalledWith(
      expect.objectContaining({
        sessionId: 'session-1',
        deviceId: 'device-1',
      }),
    );
  });

  it('fails with a stable app error code when user or session cannot be resolved', async () => {
    const service = new AuthSessionIssuer(
      {
        create: jest.fn().mockResolvedValue(null),
      } as never,
      {
        findById: jest.fn().mockResolvedValue(null),
      } as never,
      {} as never,
    );

    await expect(
      service.issue({
        userId: 'user-1',
        deviceType: 'mobile',
        deviceId: 'device-1',
      }),
    ).rejects.toMatchObject<Partial<InternalApplicationError>>({
      errorCode: ERROR_CODES.AUTH_SESSION_ISSUE_FAILED,
    });
  });
});

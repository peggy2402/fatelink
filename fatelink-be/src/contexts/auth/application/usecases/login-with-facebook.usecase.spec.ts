import type { FacebookAuthService } from '@shared/contracts/facebook-auth.service';
import type { InternalApplicationError } from '@shared/errors/application-error';
import { ERROR_CODES } from '@shared/errors/error-codes';
import { LoginWithFacebookUseCase } from './login-with-facebook.usecase';

describe('LoginWithFacebookUseCase', () => {
  it('links an existing user by email to a facebook identity', async () => {
    const facebookAuthService: FacebookAuthService = {
      authenticate: jest.fn().mockResolvedValue({
        email: 'user@example.com',
        facebookId: 'facebook-123',
        name: 'User',
      }),
    };
    const userRepository = {
      findByEmail: jest.fn().mockResolvedValue({
        id: 'user-1',
        email: 'user@example.com',
        name: 'User',
      }),
      createProfileAccount: jest.fn(),
    };
    const authIdentityRepository = {
      findByProvider: jest.fn().mockResolvedValue(null),
      linkFacebookIdentity: jest.fn().mockResolvedValue({
        userId: 'user-1',
        provider: 'facebook',
        providerUserId: 'facebook-123',
      }),
    };
    const issueAuthSessionService = {
      issue: jest.fn().mockResolvedValue({
        user: { id: 'user-1' },
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      }),
    };

    const useCase = new LoginWithFacebookUseCase(
      facebookAuthService,
      userRepository as never,
      authIdentityRepository as never,
      issueAuthSessionService as never,
    );

    const result = await useCase.execute({
      accessToken: 'fb-token',
      deviceType: 'mobile',
      deviceId: 'device-1',
      context: { userAgent: 'jest' },
    });

    expect(authIdentityRepository.linkFacebookIdentity).toHaveBeenCalledWith({
      userId: 'user-1',
      facebookId: 'facebook-123',
      email: 'user@example.com',
    });
    expect(issueAuthSessionService.issue).toHaveBeenCalledWith({
      userId: 'user-1',
      deviceType: 'mobile',
      deviceId: 'device-1',
      context: { userAgent: 'jest' },
    });
    expect(result.accessToken).toBe('access-token');
  });

  it('uses an existing facebook identity without relinking', async () => {
    const facebookAuthService: FacebookAuthService = {
      authenticate: jest.fn().mockResolvedValue({
        email: 'user@example.com',
        facebookId: 'facebook-123',
      }),
    };
    const userRepository = {
      findById: jest.fn().mockResolvedValue({ id: 'user-1' }),
      findByEmail: jest.fn(),
      createProfileAccount: jest.fn(),
    };
    const authIdentityRepository = {
      findByProvider: jest.fn().mockResolvedValue({ userId: 'user-1' }),
      linkFacebookIdentity: jest.fn(),
    };
    const issueAuthSessionService = {
      issue: jest.fn().mockResolvedValue({
        user: { id: 'user-1' },
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      }),
    };

    const useCase = new LoginWithFacebookUseCase(
      facebookAuthService,
      userRepository as never,
      authIdentityRepository as never,
      issueAuthSessionService as never,
    );

    await useCase.execute({
      accessToken: 'fb-token',
      deviceType: 'mobile',
      deviceId: 'device-1',
    });

    expect(userRepository.findById).toHaveBeenCalledWith('user-1');
    expect(authIdentityRepository.linkFacebookIdentity).not.toHaveBeenCalled();
    expect(userRepository.createProfileAccount).not.toHaveBeenCalled();
  });

  it('creates a user when no facebook identity or email match exists', async () => {
    const facebookAuthService: FacebookAuthService = {
      authenticate: jest.fn().mockResolvedValue({
        email: 'new@example.com',
        facebookId: 'facebook-999',
        name: 'New User',
        avatar: 'avatar.png',
      }),
    };
    const userRepository = {
      findById: jest.fn(),
      findByEmail: jest.fn().mockResolvedValue(null),
      createProfileAccount: jest.fn().mockResolvedValue({ id: 'user-new' }),
    };
    const authIdentityRepository = {
      findByProvider: jest.fn().mockResolvedValue(null),
      linkFacebookIdentity: jest.fn(),
    };
    const issueAuthSessionService = {
      issue: jest.fn().mockResolvedValue({
        user: { id: 'user-new' },
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      }),
    };

    const useCase = new LoginWithFacebookUseCase(
      facebookAuthService,
      userRepository as never,
      authIdentityRepository as never,
      issueAuthSessionService as never,
    );

    await useCase.execute({
      accessToken: 'fb-token',
      deviceType: 'mobile',
      deviceId: 'device-1',
    });

    expect(userRepository.createProfileAccount).toHaveBeenCalledWith({
      email: 'new@example.com',
      name: 'New User',
      avatar: 'avatar.png',
    });
  });

  it('fails when a linked facebook identity points to a missing user', async () => {
    const facebookAuthService: FacebookAuthService = {
      authenticate: jest.fn().mockResolvedValue({
        email: 'user@example.com',
        facebookId: 'facebook-123',
      }),
    };
    const userRepository = {
      findById: jest.fn().mockResolvedValue(null),
    };
    const authIdentityRepository = {
      findByProvider: jest.fn().mockResolvedValue({ userId: 'missing-user' }),
    };

    const useCase = new LoginWithFacebookUseCase(
      facebookAuthService,
      userRepository as never,
      authIdentityRepository as never,
      {} as never,
    );

    await expect(
      useCase.execute({
        accessToken: 'fb-token',
        deviceType: 'mobile',
        deviceId: 'device-1',
      }),
    ).rejects.toMatchObject<Partial<InternalApplicationError>>({
      errorCode: ERROR_CODES.AUTH_FACEBOOK_PROFILE_ORPHANED,
    });
  });
});

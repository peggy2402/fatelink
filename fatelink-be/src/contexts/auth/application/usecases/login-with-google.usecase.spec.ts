import type { GoogleAuthService } from '@shared/contracts/google-auth.service';
import type { InternalApplicationError } from '@shared/errors/application-error';
import { ERROR_CODES } from '@shared/errors/error-codes';
import { LoginWithGoogleUseCase } from './login-with-google.usecase';

describe('LoginWithGoogleUseCase', () => {
  it('uses domain user id instead of persistence-specific _id', async () => {
    const googleAuthService: GoogleAuthService = {
      verifyIdToken: jest.fn().mockResolvedValue({
        email: 'user@example.com',
        googleId: 'google-123',
      }),
    };
    const userRepository = {
      findById: jest.fn(),
      findByEmail: jest.fn().mockResolvedValue({
        id: 'user-123',
        email: 'user@example.com',
        name: 'User',
        avatar: '',
        googleId: 'google-123',
        latestEmotion: 'Binh yen',
        emotions: {
          stress: 1,
          loneliness: 1,
          sadness: 1,
          calmness: 1,
          warmth: 1,
          happiness: 1,
        },
        personality: [1, 2, 3],
        bio: '',
        fcmToken: '',
      }),
    };
    const authIdentityRepository = {
      findByProvider: jest.fn().mockResolvedValue(null),
      linkGoogleIdentity: jest.fn(),
    };
    const issueAuthSessionService = {
      issue: jest.fn().mockResolvedValue({
        user: {
          id: 'user-123',
          email: 'user@example.com',
          name: 'User',
          avatar: '',
          googleId: 'google-123',
          latestEmotion: 'Binh yen',
          emotions: {
            stress: 1,
            loneliness: 1,
            sadness: 1,
            calmness: 1,
            warmth: 1,
            happiness: 1,
          },
          personality: [1, 2, 3],
          bio: '',
          fcmToken: '',
        },
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      }),
    };

    const useCase = new LoginWithGoogleUseCase(
      googleAuthService,
      userRepository as never,
      authIdentityRepository as never,
      issueAuthSessionService as never,
    );

    const result = await useCase.execute({
      token: 'google-token',
      deviceType: 'mobile',
      deviceId: 'device-1',
      context: { ipAddress: '127.0.0.1' },
    });

    expect(issueAuthSessionService.issue).toHaveBeenCalledWith({
      userId: 'user-123',
      deviceType: 'mobile',
      deviceId: 'device-1',
      context: { ipAddress: '127.0.0.1' },
    });
    expect(authIdentityRepository.linkGoogleIdentity).toHaveBeenCalledWith({
      userId: 'user-123',
      googleId: 'google-123',
      email: 'user@example.com',
    });
    expect(result.accessToken).toBe('access-token');
    expect(result.refreshToken).toBe('refresh-token');
  });

  it('uses an existing google identity without relinking', async () => {
    const googleAuthService: GoogleAuthService = {
      verifyIdToken: jest.fn().mockResolvedValue({
        email: 'user@example.com',
        googleId: 'google-123',
      }),
    };
    const userRepository = {
      findById: jest.fn().mockResolvedValue({
        id: 'user-123',
        email: 'user@example.com',
      }),
      findByEmail: jest.fn(),
      createProfileAccount: jest.fn(),
    };
    const authIdentityRepository = {
      findByProvider: jest.fn().mockResolvedValue({ userId: 'user-123' }),
      linkGoogleIdentity: jest.fn(),
    };
    const issueAuthSessionService = {
      issue: jest.fn().mockResolvedValue({
        user: { id: 'user-123' },
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      }),
    };

    const useCase = new LoginWithGoogleUseCase(
      googleAuthService,
      userRepository as never,
      authIdentityRepository as never,
      issueAuthSessionService as never,
    );

    await useCase.execute({
      token: 'google-token',
      deviceType: 'mobile',
      deviceId: 'device-1',
    });

    expect(userRepository.findById).toHaveBeenCalledWith('user-123');
    expect(authIdentityRepository.linkGoogleIdentity).not.toHaveBeenCalled();
    expect(userRepository.createProfileAccount).not.toHaveBeenCalled();
  });

  it('creates a user when no email match exists', async () => {
    const googleAuthService: GoogleAuthService = {
      verifyIdToken: jest.fn().mockResolvedValue({
        email: 'new@example.com',
        googleId: 'google-999',
        name: 'New User',
        avatar: 'avatar.png',
      }),
    };
    const userRepository = {
      findById: jest.fn(),
      findByEmail: jest.fn().mockResolvedValue(null),
      createProfileAccount: jest.fn().mockResolvedValue({
        id: 'user-new',
        email: 'new@example.com',
      }),
    };
    const authIdentityRepository = {
      findByProvider: jest.fn().mockResolvedValue(null),
      linkGoogleIdentity: jest.fn(),
    };
    const issueAuthSessionService = {
      issue: jest.fn().mockResolvedValue({
        user: { id: 'user-new' },
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      }),
    };

    const useCase = new LoginWithGoogleUseCase(
      googleAuthService,
      userRepository as never,
      authIdentityRepository as never,
      issueAuthSessionService as never,
    );

    await useCase.execute({
      token: 'google-token',
      deviceType: 'mobile',
      deviceId: 'device-1',
    });

    expect(userRepository.createProfileAccount).toHaveBeenCalledWith({
      email: 'new@example.com',
      name: 'New User',
      avatar: 'avatar.png',
    });
  });

  it('fails when a linked google identity points to a missing user', async () => {
    const googleAuthService: GoogleAuthService = {
      verifyIdToken: jest.fn().mockResolvedValue({
        email: 'user@example.com',
        googleId: 'google-123',
      }),
    };
    const userRepository = {
      findById: jest.fn().mockResolvedValue(null),
    };
    const authIdentityRepository = {
      findByProvider: jest.fn().mockResolvedValue({ userId: 'missing-user' }),
    };

    const useCase = new LoginWithGoogleUseCase(
      googleAuthService,
      userRepository as never,
      authIdentityRepository as never,
      {} as never,
    );

    await expect(
      useCase.execute({
        token: 'google-token',
        deviceType: 'mobile',
        deviceId: 'device-1',
      }),
    ).rejects.toMatchObject<Partial<InternalApplicationError>>({
      errorCode: ERROR_CODES.AUTH_GOOGLE_PROFILE_ORPHANED,
    });
  });
});

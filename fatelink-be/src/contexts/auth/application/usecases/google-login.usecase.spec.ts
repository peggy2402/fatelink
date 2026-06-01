import type { GoogleAuthService } from '@shared/contracts/google-auth.service';
import type { TokenService } from '@shared/contracts/token.service';
import { GoogleLoginUseCase } from './google-login.usecase';

describe('GoogleLoginUseCase', () => {
  it('uses domain user id instead of persistence-specific _id', async () => {
    const googleAuthService: GoogleAuthService = {
      verifyIdToken: jest.fn().mockResolvedValue({
        email: 'user@example.com',
        googleId: 'google-123',
      }),
    };
    const userRepository = {
      findOrCreate: jest.fn().mockResolvedValue({
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
        tokenVersion: 0,
      }),
    };
    const tokenService: TokenService = {
      signAccessToken: jest.fn().mockReturnValue('access-token'),
      verifyAccessToken: jest.fn(),
      signAdminAccessToken: jest.fn(),
      verifyAdminAccessToken: jest.fn(),
    };

    const useCase = new GoogleLoginUseCase(
      googleAuthService,
      userRepository,
      tokenService,
    );

    const result = await useCase.execute({ token: 'google-token' });

    expect(tokenService.signAccessToken).toHaveBeenCalledWith({
      sub: 'user-123',
      email: 'user@example.com',
      tokenVersion: 0,
    });
    expect(result.accessToken).toBe('access-token');
  });
});

import type { AuthSessionContext } from '@contexts/auth/application/contracts/auth-session-context';
import type { GoogleAuthService } from '@shared/contracts/google-auth.service';
import type { AuthIdentityRepository } from '@contexts/auth/domain/repositories/auth-identity.repository';
import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';
import type { AuthSessionIssuer } from '@contexts/auth/application/services/auth-session-issuer.service';
import { InternalApplicationError } from '@shared/errors/application-error';
import { ERROR_CODES } from '@shared/errors/error-codes';

export class LoginWithGoogleUseCase {
  constructor(
    private readonly googleAuthService: GoogleAuthService,
    private readonly userRepository: UserRepository,
    private readonly authIdentityRepository: AuthIdentityRepository,
    private readonly authSessionIssuer: AuthSessionIssuer,
  ) {}

  async execute(input: {
    token: string;
    deviceType: string;
    deviceId: string;
    context?: AuthSessionContext;
  }) {
    const profile = await this.googleAuthService.verifyIdToken(input.token);
    const existingIdentity = await this.authIdentityRepository.findByProvider(
      'google',
      profile.googleId,
    );

    if (existingIdentity) {
      const linkedUser = await this.userRepository.findById(
        existingIdentity.userId,
      );
      if (!linkedUser) {
        throw new InternalApplicationError(
          'Linked Google identity points to a missing user.',
          ERROR_CODES.AUTH_GOOGLE_PROFILE_ORPHANED,
        );
      }
      return this.authSessionIssuer.issue({
        userId: linkedUser.id || '',
        deviceType: input.deviceType,
        deviceId: input.deviceId,
        context: input.context,
      });
    }

    const existingUser = await this.userRepository.findByEmail(profile.email);
    const user =
      existingUser ||
      (await this.userRepository.createProfileAccount({
        email: profile.email,
        name: profile.name,
        avatar: profile.avatar,
      }));

    await this.authIdentityRepository.linkGoogleIdentity({
      userId: user.id || '',
      googleId: profile.googleId,
      email: profile.email,
    });

    return this.authSessionIssuer.issue({
      userId: user.id || '',
      deviceType: input.deviceType,
      deviceId: input.deviceId,
      context: input.context,
    });
  }
}

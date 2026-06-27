import type { AuthSessionContext } from '@contexts/auth/application/contracts/auth-session-context';
import type { FacebookAuthService } from '@shared/contracts/facebook-auth.service';
import type { AuthIdentityRepository } from '@contexts/auth/domain/repositories/auth-identity.repository';
import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';
import type { AuthSessionIssuer } from '@contexts/auth/application/services/auth-session-issuer.service';
import { InternalApplicationError } from '@shared/errors/application-error';
import { ERROR_CODES } from '@shared/errors/error-codes';

export class LoginWithFacebookUseCase {
  constructor(
    private readonly facebookAuthService: FacebookAuthService,
    private readonly userRepository: UserRepository,
    private readonly authIdentityRepository: AuthIdentityRepository,
    private readonly authSessionIssuer: AuthSessionIssuer,
  ) {}

  async execute(input: {
    accessToken: string;
    deviceType: string;
    deviceId: string;
    context?: AuthSessionContext;
  }) {
    const profile = await this.facebookAuthService.authenticate(input);
    const existingByFacebookId =
      await this.authIdentityRepository.findByProvider(
        'facebook',
        profile.facebookId,
      );

    if (existingByFacebookId) {
      const user = await this.userRepository.findById(
        existingByFacebookId.userId,
      );
      if (!user) {
        throw new InternalApplicationError(
          'Linked Facebook identity points to a missing user.',
          ERROR_CODES.AUTH_FACEBOOK_PROFILE_ORPHANED,
        );
      }
      return this.authSessionIssuer.issue({
        userId: user.id || '',
        deviceType: input.deviceType,
        deviceId: input.deviceId,
        context: input.context,
      });
    }

    const existingByEmail = await this.userRepository.findByEmail(
      profile.email,
    );
    if (existingByEmail?.id) {
      await this.authIdentityRepository.linkFacebookIdentity({
        userId: existingByEmail.id,
        facebookId: profile.facebookId,
        email: profile.email,
      });
      return this.authSessionIssuer.issue({
        userId: existingByEmail.id || '',
        deviceType: input.deviceType,
        deviceId: input.deviceId,
        context: input.context,
      });
    }

    const createdUser = await this.userRepository.createProfileAccount({
      email: profile.email,
      name: profile.name,
      avatar: profile.avatar,
    });
    await this.authIdentityRepository.linkFacebookIdentity({
      userId: createdUser.id || '',
      facebookId: profile.facebookId,
      email: profile.email,
    });

    return this.authSessionIssuer.issue({
      userId: createdUser.id || '',
      deviceType: input.deviceType,
      deviceId: input.deviceId,
      context: input.context,
    });
  }
}

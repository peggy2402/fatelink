import type { AuthSessionContext } from '@contexts/auth/application/contracts/auth-session-context';
import type { ZaloAuthService } from '@shared/contracts/zalo-auth.service';
import type { AuthIdentityRepository } from '@contexts/auth/domain/repositories/auth-identity.repository';
import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';
import type { AuthSessionIssuer } from '@contexts/auth/application/services/auth-session-issuer.service';
import { InternalApplicationError } from '@shared/errors/application-error';
import { ERROR_CODES } from '@shared/errors/error-codes';

export class LoginWithZaloUseCase {
  constructor(
    private readonly zaloAuthService: ZaloAuthService,
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
    const profile = await this.zaloAuthService.authenticate(input);
    const existingIdentity = await this.authIdentityRepository.findByProvider(
      'zalo',
      profile.zaloId,
    );

    if (existingIdentity) {
      const linkedUser = await this.userRepository.findById(
        existingIdentity.userId,
      );
      if (!linkedUser) {
        throw new InternalApplicationError(
          'Linked Zalo identity points to a missing user.',
          ERROR_CODES.AUTH_ZALO_PROFILE_ORPHANED,
        );
      }
      return this.authSessionIssuer.issue({
        userId: linkedUser.id || '',
        deviceType: input.deviceType,
        deviceId: input.deviceId,
        context: input.context,
      });
    }

    const existingUser = profile.email
      ? await this.userRepository.findByEmail(profile.email)
      : null;
    const user =
      existingUser ||
      (await this.userRepository.createProfileAccount({
        email: profile.email,
        name: profile.name,
        avatar: profile.avatar,
      }));

    await this.authIdentityRepository.linkZaloIdentity({
      userId: user.id || '',
      zaloId: profile.zaloId,
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

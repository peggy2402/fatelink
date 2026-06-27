import type { AuthSessionContext } from '@contexts/auth/application/contracts/auth-session-context';
import type { TikTokAuthService } from '@shared/contracts/tiktok-auth.service';
import type { AuthIdentityRepository } from '@contexts/auth/domain/repositories/auth-identity.repository';
import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';
import type { AuthSessionIssuer } from '@contexts/auth/application/services/auth-session-issuer.service';
import { InternalApplicationError } from '@shared/errors/application-error';
import { ERROR_CODES } from '@shared/errors/error-codes';

export class LoginWithTikTokUseCase {
  constructor(
    private readonly tikTokAuthService: TikTokAuthService,
    private readonly userRepository: UserRepository,
    private readonly authIdentityRepository: AuthIdentityRepository,
    private readonly authSessionIssuer: AuthSessionIssuer,
  ) {}

  async execute(input: {
    accessToken?: string;
    code?: string;
    codeVerifier?: string;
    deviceType: string;
    deviceId: string;
    context?: AuthSessionContext;
  }) {
    const accessToken =
      input.accessToken ||
      (
        await this.tikTokAuthService.exchangeAuthorizationCode({
          code: input.code || '',
          codeVerifier: input.codeVerifier || '',
        })
      ).accessToken;
    const profile = await this.tikTokAuthService.authenticate({ accessToken });
    const existingIdentity = await this.authIdentityRepository.findByProvider(
      'tiktok',
      profile.tikTokId,
    );

    if (existingIdentity) {
      const linkedUser = await this.userRepository.findById(
        existingIdentity.userId,
      );
      if (!linkedUser) {
        throw new InternalApplicationError(
          'Linked TikTok identity points to a missing user.',
          ERROR_CODES.AUTH_TIKTOK_PROFILE_ORPHANED,
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

    await this.authIdentityRepository.linkTikTokIdentity({
      userId: user.id || '',
      tikTokId: profile.tikTokId,
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

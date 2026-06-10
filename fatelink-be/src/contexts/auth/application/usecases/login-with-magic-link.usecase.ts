import type { AuthSessionContext } from '@contexts/auth/application/contracts/auth-session-context';
import type { MagicLinkAuthService } from '@shared/contracts/magic-link-auth.service';
import type { AuthSessionIssuer } from '@contexts/auth/application/services/auth-session-issuer.service';

export class LoginWithMagicLinkUseCase {
  constructor(
    private readonly magicLinkAuthService: MagicLinkAuthService,
    private readonly authSessionIssuer: AuthSessionIssuer,
  ) {}

  async execute(input: {
    token: string;
    deviceType: string;
    deviceId: string;
    context?: AuthSessionContext;
  }) {
    const user = await this.magicLinkAuthService.authenticate(input);

    return this.authSessionIssuer.issue({
      userId: user.id || '',
      deviceType: input.deviceType,
      deviceId: input.deviceId,
      context: input.context,
    });
  }
}

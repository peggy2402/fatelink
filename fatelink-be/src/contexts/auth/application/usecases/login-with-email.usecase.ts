import type { AuthSessionContext } from '@contexts/auth/application/contracts/auth-session-context';
import type { EmailAuthService } from '@shared/contracts/email-auth.service';
import type { AuthSessionIssuer } from '@contexts/auth/application/services/auth-session-issuer.service';

export class LoginWithEmailUseCase {
  constructor(
    private readonly emailAuthService: EmailAuthService,
    private readonly authSessionIssuer: AuthSessionIssuer,
  ) {}

  async execute(input: {
    email: string;
    password: string;
    deviceType: string;
    deviceId: string;
    context?: AuthSessionContext;
  }) {
    const user = await this.emailAuthService.authenticate(input);

    return this.authSessionIssuer.issue({
      userId: user.id || '',
      deviceType: input.deviceType,
      deviceId: input.deviceId,
      context: input.context,
    });
  }
}

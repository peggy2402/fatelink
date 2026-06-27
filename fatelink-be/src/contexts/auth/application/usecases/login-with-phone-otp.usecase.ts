import type { AuthSessionContext } from '@contexts/auth/application/contracts/auth-session-context';
import type { PhoneAuthService } from '@shared/contracts/phone-auth.service';
import type { AuthSessionIssuer } from '@contexts/auth/application/services/auth-session-issuer.service';

export class LoginWithPhoneOtpUseCase {
  constructor(
    private readonly phoneAuthService: PhoneAuthService,
    private readonly authSessionIssuer: AuthSessionIssuer,
  ) {}

  async execute(input: {
    phoneNumber: string;
    otpCode: string;
    deviceType: string;
    deviceId: string;
    context?: AuthSessionContext;
  }) {
    const user = await this.phoneAuthService.authenticate(input);

    return this.authSessionIssuer.issue({
      userId: user.id || '',
      deviceType: input.deviceType,
      deviceId: input.deviceId,
      context: input.context,
    });
  }
}

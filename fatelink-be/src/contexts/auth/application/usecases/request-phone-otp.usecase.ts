import type { PhoneAuthService } from '@shared/contracts/phone-auth.service';

export class RequestPhoneOtpUseCase {
  constructor(private readonly phoneAuthService: PhoneAuthService) {}

  execute(input: { phoneNumber: string; name?: string }) {
    return this.phoneAuthService.requestOtp(input);
  }
}

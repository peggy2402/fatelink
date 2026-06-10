import type { User } from '@contexts/users/domain/entities/user';

export interface PhoneAuthService {
  requestOtp(input: { phoneNumber: string; name?: string }): Promise<{
    message: string;
    otpCode?: string;
    expiresAt: Date;
  }>;
  authenticate(input: { phoneNumber: string; otpCode: string }): Promise<User>;
}

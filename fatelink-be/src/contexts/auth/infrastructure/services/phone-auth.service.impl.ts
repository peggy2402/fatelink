import type { ConfigService } from '@nestjs/config';
import { randomInt } from 'crypto';
import type { AuthChallengeRepository } from '@contexts/auth/domain/repositories/auth-challenge.repository';
import type { AuthIdentityRepository } from '@contexts/auth/domain/repositories/auth-identity.repository';
import type { PhoneAuthService } from '@shared/contracts/phone-auth.service';
import type { PhoneOtpDeliveryService } from '@shared/contracts/phone-otp-delivery.service';
import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';
import {
  BadRequestApplicationError,
  UnauthorizedApplicationError,
} from '@shared/errors/application-error';
import { AUTH_ENV } from '@contexts/auth/infrastructure/config/auth-env';
import { ERROR_CODES } from '@shared/errors/error-codes';
import type { SecretHashService } from './secret-hash.service';

export class PhoneAuthServiceImpl implements PhoneAuthService {
  constructor(
    private readonly userRepository: UserRepository,
    private readonly authIdentityRepository: AuthIdentityRepository,
    private readonly authChallengeRepository: AuthChallengeRepository,
    private readonly configService: ConfigService,
    private readonly secretHashService: SecretHashService,
    private readonly phoneOtpDeliveryService: PhoneOtpDeliveryService,
  ) {}

  async requestOtp(input: { phoneNumber: string; name?: string }) {
    const otpCode = `${randomInt(100000, 999999)}`;
    const expiresAt = new Date(
      Date.now() +
        this.getExpiryMinutes(AUTH_ENV.phoneOtpExpiresInMinutes) * 60000,
    );

    await this.authChallengeRepository.save({
      type: 'phone_otp',
      key: input.phoneNumber,
      secretHash: this.secretHashService.hash(otpCode),
      expiresAt,
      attemptCount: 0,
      maxAttempts: 5,
      metadata: input.name ? { name: input.name } : {},
    });

    if (!this.shouldExposeChallenge()) {
      await this.phoneOtpDeliveryService.sendOtp({
        phoneNumber: input.phoneNumber,
        otpCode,
        requestId: `otp:${input.phoneNumber}:${Date.now()}`,
      });
    }

    return {
      message: 'OTP đã được tạo.',
      otpCode: this.shouldExposeChallenge() ? otpCode : undefined,
      expiresAt,
    };
  }

  async authenticate(input: { phoneNumber: string; otpCode: string }) {
    const challenge = await this.authChallengeRepository.find(
      'phone_otp',
      input.phoneNumber,
    );
    const isExpired = !!challenge && challenge.expiresAt.getTime() < Date.now();
    const isLocked = !!challenge?.lockedAt;
    const isValidOtp =
      !!challenge &&
      !isExpired &&
      !isLocked &&
      this.secretHashService.verify(input.otpCode, challenge.secretHash);

    if (!challenge || !isValidOtp) {
      if (challenge && !isExpired && !isLocked) {
        const failedChallenge =
          await this.authChallengeRepository.registerFailedAttempt(
            'phone_otp',
            input.phoneNumber,
          );

        if (failedChallenge?.lockedAt) {
          throw new UnauthorizedApplicationError(
            'OTP đã bị khóa do nhập sai quá số lần cho phép.',
            ERROR_CODES.AUTH_PHONE_OTP_ATTEMPTS_EXCEEDED,
          );
        }
      }

      throw new UnauthorizedApplicationError(
        'OTP không hợp lệ hoặc đã hết hạn.',
        ERROR_CODES.AUTH_PHONE_OTP_INVALID,
      );
    }

    await this.authChallengeRepository.consume('phone_otp', input.phoneNumber);

    const identity = await this.authIdentityRepository.findByProvider(
      'phone',
      input.phoneNumber,
    );
    if (identity) {
      const user = await this.userRepository.findById(identity.userId);
      if (!user) {
        throw new BadRequestApplicationError(
          'Tài khoản số điện thoại không tồn tại.',
          ERROR_CODES.AUTH_PHONE_ACCOUNT_NOT_FOUND,
        );
      }
      return user;
    }

    const createdUser = await this.userRepository.createProfileAccount({
      email: `${input.phoneNumber.replace(/\D/g, '')}@phone.local`,
      name: challenge.metadata?.name || input.phoneNumber,
      avatar: '',
    });
    await this.authIdentityRepository.linkPhoneIdentity({
      userId: createdUser.id || '',
      phoneNumber: input.phoneNumber,
    });

    return createdUser;
  }

  private getExpiryMinutes(key: string) {
    return Number(this.configService.get<string>(key) || '5');
  }

  private shouldExposeChallenge() {
    return (
      (this.configService.get<string>(AUTH_ENV.authExposeDebugChallenges) ||
        'false') === 'true'
    );
  }
}

import type { ConfigService } from '@nestjs/config';
import type { PhoneOtpDeliveryService } from '@shared/contracts/phone-otp-delivery.service';
import { InternalApplicationError } from '@shared/errors/application-error';
import { ERROR_CODES } from '@shared/errors/error-codes';
import { AUTH_ENV } from '@contexts/auth/infrastructure/config/auth-env';

type TwilioMessageResponse = {
  sid?: string;
  error_code?: number | null;
  error_message?: string | null;
  status?: string;
};

export class TwilioPhoneOtpDeliveryServiceImpl implements PhoneOtpDeliveryService {
  constructor(private readonly configService: ConfigService) {}

  async sendOtp(input: {
    phoneNumber: string;
    otpCode: string;
    requestId: string;
  }): Promise<void> {
    const accountSid = this.configService.getOrThrow<string>(
      AUTH_ENV.twilioAccountSid,
    );
    const authToken = this.configService.getOrThrow<string>(
      AUTH_ENV.twilioAuthToken,
    );
    const endpoint =
      this.configService.get<string>(AUTH_ENV.twilioEndpoint) ||
      `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`;
    const fromNumber = this.configService.get<string>(
      AUTH_ENV.twilioFromNumber,
    );
    const messagingServiceSid = this.configService.get<string>(
      AUTH_ENV.twilioMessagingServiceSid,
    );

    if (!fromNumber && !messagingServiceSid) {
      throw new InternalApplicationError(
        'Thiếu cấu hình Twilio sender. Cần TWILIO_FROM_NUMBER hoặc TWILIO_MESSAGING_SERVICE_SID.',
        ERROR_CODES.COMMON_INTERNAL_ERROR,
      );
    }

    const body = new URLSearchParams({
      To: this.normalizePhoneNumber(input.phoneNumber),
      Body: this.buildOtpContent(input.otpCode),
      ...(fromNumber ? { From: fromNumber } : {}),
      ...(messagingServiceSid
        ? { MessagingServiceSid: messagingServiceSid }
        : {}),
    });

    const response = await fetch(endpoint, {
      method: 'POST',
      headers: {
        Authorization: `Basic ${Buffer.from(`${accountSid}:${authToken}`).toString('base64')}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body,
    });

    if (!response.ok) {
      throw new InternalApplicationError(
        'Không thể kết nối tới dịch vụ Twilio để gửi OTP.',
        ERROR_CODES.COMMON_INTERNAL_ERROR,
      );
    }

    const result = (await response.json()) as TwilioMessageResponse;

    if (
      result.error_code ||
      result.status === 'failed' ||
      result.status === 'undelivered'
    ) {
      throw new InternalApplicationError(
        `Twilio từ chối gửi OTP${result.error_message ? `: ${result.error_message}` : '.'}`,
        ERROR_CODES.COMMON_INTERNAL_ERROR,
      );
    }
  }

  private buildOtpContent(otpCode: string) {
    const template =
      this.configService.get<string>(AUTH_ENV.twilioOtpTemplate) ||
      'Ma xac thuc cua ban la {{code}}';
    return template.replace('{{code}}', otpCode);
  }

  private normalizePhoneNumber(phoneNumber: string) {
    return phoneNumber.startsWith('+') ? phoneNumber : `+${phoneNumber}`;
  }
}

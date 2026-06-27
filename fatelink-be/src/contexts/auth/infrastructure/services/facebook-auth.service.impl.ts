import type { ConfigService } from '@nestjs/config';
import type {
  FacebookAuthService,
  FacebookUserProfile,
} from '@shared/contracts/facebook-auth.service';
import {
  BadRequestApplicationError,
  UnauthorizedApplicationError,
} from '@shared/errors/application-error';
import { AUTH_ENV } from '@contexts/auth/infrastructure/config/auth-env';
import { ERROR_CODES } from '@shared/errors/error-codes';

type FacebookMeResponse = {
  id: string;
  email?: string;
  name?: string;
  picture?: { data?: { url?: string } };
};

export class FacebookAuthServiceImpl implements FacebookAuthService {
  constructor(private readonly configService: ConfigService) {}

  async authenticate(input: {
    accessToken: string;
  }): Promise<FacebookUserProfile> {
    if (!input.accessToken) {
      throw new BadRequestApplicationError(
        'Facebook access token là bắt buộc.',
        ERROR_CODES.AUTH_FACEBOOK_TOKEN_REQUIRED,
      );
    }

    const baseUrl =
      this.configService.get<string>(AUTH_ENV.facebookGraphApiUrl) ||
      'https://graph.facebook.com';
    const response = await fetch(
      `${baseUrl}/me?fields=id,name,email,picture.type(large)&access_token=${encodeURIComponent(input.accessToken)}`,
    );

    if (!response.ok) {
      throw new UnauthorizedApplicationError(
        'Facebook access token không hợp lệ hoặc đã hết hạn.',
        ERROR_CODES.AUTH_FACEBOOK_TOKEN_INVALID,
      );
    }

    const profile = (await response.json()) as FacebookMeResponse;

    if (!profile.id || !profile.email) {
      throw new BadRequestApplicationError(
        'Tài khoản Facebook chưa cung cấp email hợp lệ.',
        ERROR_CODES.AUTH_FACEBOOK_EMAIL_MISSING,
      );
    }

    return {
      email: profile.email,
      name: profile.name,
      avatar: profile.picture?.data?.url,
      facebookId: profile.id,
    };
  }
}

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

    if (!profile.id) {
      throw new BadRequestApplicationError(
        'Không thể lấy thông tin định danh từ tài khoản Facebook.',
        ERROR_CODES.AUTH_FACEBOOK_TOKEN_INVALID,
      );
    }

    const email = profile.email || `fb_${profile.id}@facebook.meyu.app`;

    return {
      email,
      name: profile.name || 'Người dùng Facebook',
      avatar: profile.picture?.data?.url,
      facebookId: profile.id,
    };
  }
}

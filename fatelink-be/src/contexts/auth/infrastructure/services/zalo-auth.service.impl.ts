import type { ConfigService } from '@nestjs/config';
import type {
  ZaloAuthService,
  ZaloUserProfile,
} from '@shared/contracts/zalo-auth.service';
import {
  BadRequestApplicationError,
  UnauthorizedApplicationError,
} from '@shared/errors/application-error';
import { AUTH_ENV } from '@contexts/auth/infrastructure/config/auth-env';
import { ERROR_CODES } from '@shared/errors/error-codes';

type ZaloMeResponse = {
  id?: string;
  name?: string;
  picture?: { data?: { url?: string } } | string;
  email?: string;
};

export class ZaloAuthServiceImpl implements ZaloAuthService {
  constructor(private readonly configService: ConfigService) {}

  async authenticate(input: {
    accessToken: string;
  }): Promise<ZaloUserProfile> {
    if (!input.accessToken) {
      throw new BadRequestApplicationError(
        'Zalo access token là bắt buộc.',
        ERROR_CODES.AUTH_ZALO_TOKEN_REQUIRED,
      );
    }

    const baseUrl =
      this.configService.get<string>(AUTH_ENV.zaloGraphApiUrl) ||
      'https://graph.zalo.me';
    const response = await fetch(
      `${baseUrl}/v2.0/me?fields=id,name,picture,email&access_token=${encodeURIComponent(input.accessToken)}`,
    );

    if (!response.ok) {
      throw new UnauthorizedApplicationError(
        'Zalo access token không hợp lệ hoặc đã hết hạn.',
        ERROR_CODES.AUTH_ZALO_TOKEN_INVALID,
      );
    }

    const profile = (await response.json()) as ZaloMeResponse;

    if (!profile.id) {
      throw new UnauthorizedApplicationError(
        'Không thể xác thực tài khoản Zalo.',
        ERROR_CODES.AUTH_ZALO_TOKEN_INVALID,
      );
    }

    return {
      zaloId: profile.id,
      email: profile.email,
      name: profile.name,
      avatar:
        typeof profile.picture === 'string'
          ? profile.picture
          : profile.picture?.data?.url,
    };
  }
}

import type { ConfigService } from '@nestjs/config';
import * as jwt from 'jsonwebtoken';
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

type FacebookIdTokenPayload = {
  iss?: string;
  aud?: string;
  sub?: string;
  name?: string;
  given_name?: string;
  family_name?: string;
  picture?: string;
  email?: string;
  exp?: number;
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

    // 1. Hỗ trợ Facebook OIDC ID Token (JWT do iOS Limited Login phát hành)
    if (input.accessToken.startsWith('eyJ')) {
      const decoded = jwt.decode(input.accessToken) as FacebookIdTokenPayload | null;
      if (!decoded || !decoded.sub) {
        throw new UnauthorizedApplicationError(
          'Facebook ID token không hợp lệ.',
          ERROR_CODES.AUTH_FACEBOOK_TOKEN_INVALID,
        );
      }

      if (decoded.exp && decoded.exp * 1000 < Date.now()) {
        throw new UnauthorizedApplicationError(
          'Facebook token đã hết hạn.',
          ERROR_CODES.AUTH_FACEBOOK_TOKEN_INVALID,
        );
      }

      const email = decoded.email || `fb_${decoded.sub}@facebook.meyu.app`;
      return {
        email,
        name: decoded.name || 'Người dùng Facebook',
        avatar: decoded.picture,
        facebookId: decoded.sub,
      };
    }

    // 2. Hỗ trợ Classic OAuth Access Token (Graph API)
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

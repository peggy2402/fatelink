import { Logger } from '@nestjs/common';
import type { ConfigService } from '@nestjs/config';
import type {
  TikTokAuthService,
  TikTokUserProfile,
} from '@shared/contracts/tiktok-auth.service';
import {
  BadRequestApplicationError,
  UnauthorizedApplicationError,
} from '@shared/errors/application-error';
import { AUTH_ENV } from '@contexts/auth/infrastructure/config/auth-env';
import { ERROR_CODES } from '@shared/errors/error-codes';

type TikTokUserInfoResponse = {
  data?: {
    user?: {
      open_id?: string;
      union_id?: string;
      display_name?: string;
      avatar_url?: string;
      email?: string;
    };
  };
};

type TikTokTokenResponse = {
  access_token?: string;
  error?: string;
  error_description?: string;
};

export class TikTokAuthServiceImpl implements TikTokAuthService {
  private readonly logger = new Logger(TikTokAuthServiceImpl.name);

  constructor(private readonly configService: ConfigService) {}

  async exchangeAuthorizationCode(input: {
    code: string;
    codeVerifier: string;
  }): Promise<{ accessToken: string }> {
    if (!input.code || !input.codeVerifier) {
      throw new BadRequestApplicationError(
        'TikTok authorization code và code verifier là bắt buộc.',
        ERROR_CODES.AUTH_TIKTOK_TOKEN_REQUIRED,
      );
    }

    const baseUrl =
      this.configService.get<string>(AUTH_ENV.tiktokApiUrl) ||
      'https://open.tiktokapis.com';
    const clientKey = this.configService.getOrThrow<string>(
      AUTH_ENV.tiktokClientKey,
    );
    const clientSecret = this.configService.getOrThrow<string>(
      AUTH_ENV.tiktokClientSecret,
    );
    const redirectUri = this.configService.getOrThrow<string>(
      AUTH_ENV.tiktokRedirectUri,
    );

    const response = await fetch(`${baseUrl}/v2/oauth/token/`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        client_key: clientKey,
        client_secret: clientSecret,
        code: input.code,
        grant_type: 'authorization_code',
        redirect_uri: redirectUri,
        code_verifier: input.codeVerifier,
      }),
    });

    if (!response.ok) {
      const errorBody = await response.text();
      this.logger.error(
        JSON.stringify({
          phase: 'exchangeAuthorizationCode',
          url: `${baseUrl}/v2/oauth/token/`,
          status: response.status,
          statusText: response.statusText,
          responseBody: errorBody,
          redirectUri,
          clientKeySuffix: clientKey.slice(-4),
          codeLength: input.code.length,
          codeVerifierLength: input.codeVerifier.length,
        }),
      );
      throw new UnauthorizedApplicationError(
        'Không thể đổi TikTok authorization code sang access token.',
        ERROR_CODES.AUTH_TIKTOK_TOKEN_INVALID,
      );
    }

    const payload = (await response.json()) as TikTokTokenResponse;
    if (!payload.access_token) {
      this.logger.error(
        JSON.stringify({
          phase: 'exchangeAuthorizationCode',
          url: `${baseUrl}/v2/oauth/token/`,
          status: response.status,
          responseBody: payload,
          redirectUri,
          clientKeySuffix: clientKey.slice(-4),
          codeLength: input.code.length,
          codeVerifierLength: input.codeVerifier.length,
        }),
      );
      throw new UnauthorizedApplicationError(
        'TikTok không trả về access token hợp lệ.',
        ERROR_CODES.AUTH_TIKTOK_TOKEN_INVALID,
      );
    }

    return {
      accessToken: payload.access_token,
    };
  }

  async authenticate(input: {
    accessToken: string;
  }): Promise<TikTokUserProfile> {
    if (!input.accessToken) {
      throw new BadRequestApplicationError(
        'TikTok access token là bắt buộc.',
        ERROR_CODES.AUTH_TIKTOK_TOKEN_REQUIRED,
      );
    }

    const baseUrl =
      this.configService.get<string>(AUTH_ENV.tiktokApiUrl) ||
      'https://open.tiktokapis.com';
    const userInfoFields = 'open_id,union_id,display_name,avatar_url';
    const response = await fetch(
      `${baseUrl}/v2/user/info/?fields=${userInfoFields}`,
      {
        headers: {
          Authorization: `Bearer ${input.accessToken}`,
        },
      },
    );

    if (!response.ok) {
      const errorBody = await response.text();
      this.logger.error(
        JSON.stringify({
          phase: 'authenticate',
          url: `${baseUrl}/v2/user/info/?fields=${userInfoFields}`,
          status: response.status,
          statusText: response.statusText,
          responseBody: errorBody,
          accessTokenSuffix: input.accessToken.slice(-6),
        }),
      );
      throw new UnauthorizedApplicationError(
        'TikTok access token không hợp lệ hoặc đã hết hạn.',
        ERROR_CODES.AUTH_TIKTOK_TOKEN_INVALID,
      );
    }

    const payload = (await response.json()) as TikTokUserInfoResponse;
    const user = payload.data?.user;
    const tikTokId = user?.union_id || user?.open_id;

    if (!tikTokId) {
      this.logger.error(
        JSON.stringify({
          phase: 'authenticate',
          url: `${baseUrl}/v2/user/info/?fields=${userInfoFields}`,
          status: response.status,
          responseBody: payload,
          accessTokenSuffix: input.accessToken.slice(-6),
        }),
      );
      throw new UnauthorizedApplicationError(
        'Không thể xác thực tài khoản TikTok.',
        ERROR_CODES.AUTH_TIKTOK_TOKEN_INVALID,
      );
    }

    return {
      tikTokId,
      email: user?.email,
      name: user?.display_name || tikTokId,
      avatar: user?.avatar_url,
    };
  }
}

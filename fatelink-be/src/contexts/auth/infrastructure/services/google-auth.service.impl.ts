import {
  OAuth2Client,
  type LoginTicket,
  type TokenPayload,
} from 'google-auth-library';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type {
  GoogleAuthService,
  GoogleUserProfile,
} from '@shared/contracts/google-auth.service';
import {
  BadRequestApplicationError,
  UnauthorizedApplicationError,
} from '@shared/errors/application-error';
import { AUTH_ENV } from '@contexts/auth/infrastructure/config/auth-env';
import { ERROR_CODES } from '@shared/errors/error-codes';

@Injectable()
export class GoogleAuthServiceImpl implements GoogleAuthService {
  private readonly googleClientId: string;
  private readonly client: OAuth2Client;

  constructor(private readonly configService: ConfigService) {
    this.googleClientId = this.configService.getOrThrow<string>(
      AUTH_ENV.googleClientId,
    );
    this.client = new OAuth2Client(this.googleClientId);
  }

  async verifyIdToken(token: string): Promise<GoogleUserProfile> {
    if (!token || token.split('.').length !== 3) {
      throw new BadRequestApplicationError(
        'Google ID token khong dung dinh dang.',
        ERROR_CODES.AUTH_GOOGLE_TOKEN_REQUIRED,
      );
    }

    let ticket: LoginTicket;
    try {
      ticket = await this.client.verifyIdToken({
        idToken: token,
        audience: this.googleClientId,
      });
    } catch {
      throw new UnauthorizedApplicationError(
        'Google ID token khong hop le hoac da het han.',
        ERROR_CODES.AUTH_GOOGLE_TOKEN_INVALID,
      );
    }

    const payload: TokenPayload | undefined = ticket.getPayload();

    if (!payload?.email || !payload.sub) {
      throw new UnauthorizedApplicationError(
        'Không thể xác thực tài khoản Google.',
        ERROR_CODES.AUTH_GOOGLE_TOKEN_INVALID,
      );
    }

    return {
      email: payload.email,
      name: payload.name,
      avatar: payload.picture,
      googleId: payload.sub,
    };
  }
}

import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OAuth2Client } from 'google-auth-library';
import { AppError } from '../../../common/errors/app-error';
import { APP_ERROR_CODES } from '../../../common/errors/app-error-codes';
import { AUTH_ENV, AuthConfig } from '../../shared/auth.constants';
import { GoogleProfile } from '../interfaces/google-profile.interface';

@Injectable()
export class GoogleTokenService {
  private readonly googleClient: OAuth2Client;
  private readonly googleClientId: string;

  constructor(private readonly configService: ConfigService<AuthConfig, true>) {
    this.googleClientId = this.configService.getOrThrow(
      AUTH_ENV.GOOGLE_CLIENT_ID,
      {
        infer: true,
      },
    );
    this.googleClient = new OAuth2Client(this.googleClientId);
  }

  async verifyIdToken(token: string): Promise<GoogleProfile> {
    try {
      const ticket = await this.googleClient.verifyIdToken({
        idToken: token,
        audience: this.googleClientId,
      });

      const payload = ticket.getPayload();
      if (!payload?.email) {
        throw new AppError(
          APP_ERROR_CODES.AUTH_GOOGLE_EMAIL_MISSING,
          undefined,
          undefined,
          {
            domain: 'auth',
            layer: 'external_api',
            kind: 'integration',
            source: 'GoogleTokenService.verifyIdToken',
            provider: 'google',
            retryable: false,
          },
        );
      }

      return {
        email: payload.email,
        name: payload.name ?? '',
        avatar: payload.picture ?? '',
        googleId: payload.sub,
      };
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }

      throw new AppError(
        APP_ERROR_CODES.AUTH_GOOGLE_TOKEN_INVALID_OR_EXPIRED,
        undefined,
        undefined,
        {
          domain: 'auth',
          layer: 'external_api',
          kind: 'integration',
          source: 'GoogleTokenService.verifyIdToken',
          provider: 'google',
          retryable: false,
        },
        error,
      );
    }
  }
}

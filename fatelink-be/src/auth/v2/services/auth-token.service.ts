import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { randomUUID } from 'crypto';
import { StringValue } from 'ms';
import { AppError } from '../../../common/errors/app-error';
import { APP_ERROR_CODES } from '../../../common/errors/app-error-codes';
import { AppLoggerService } from '../../../common/logger/logger.service';
import { UserDocument } from '../../../users/schemas/user.schema';
import { UsersService } from '../../../users/users.service';
import { AUTH_ENV } from '../../shared/auth.constants';

type RefreshTokenPayload = {
  sub: string;
  email: string;
  tokenVersion: number;
  refreshTokenVersion: number;
  jti: string;
  type: 'refresh';
};

type IssuedTokenPair = {
  user: UserDocument;
  accessToken: string;
  refreshToken: string;
};

@Injectable()
export class AuthTokenService {
  constructor(
    private readonly configService: ConfigService,
    private readonly jwtService: JwtService,
    private readonly usersService: UsersService,
    private readonly logger: AppLoggerService,
  ) {}

  issueAccessToken(user: UserDocument): string {
    const payload = {
      sub: user._id,
      email: user.email,
      tokenVersion: user.tokenVersion || 0,
    };

    return this.jwtService.sign(payload, {
      expiresIn: this.configService.getOrThrow<StringValue>(
        AUTH_ENV.ACCESS_TOKEN_EXPIRES_IN,
      ),
    });
  }

  private buildRefreshTokenPayload(
    user: UserDocument,
    refreshTokenId: string,
  ): RefreshTokenPayload {
    return {
      sub: user.id,
      email: user.email,
      tokenVersion: user.tokenVersion ?? 0,
      refreshTokenVersion: user.refreshTokenVersion ?? 0,
      jti: refreshTokenId,
      type: 'refresh',
    };
  }

  async issueTokenPair(user: UserDocument): Promise<IssuedTokenPair> {
    const refreshTokenId = randomUUID();
    const rotatedUser: UserDocument | null =
      await this.usersService.rotateRefreshToken(user.id, refreshTokenId);

    if (!rotatedUser) {
      throw new AppError(
        APP_ERROR_CODES.AUTH_SESSION_INIT_FAILED,
        undefined,
        { userId: user.id },
        {
          domain: 'auth',
          layer: 'repository',
          kind: 'infrastructure',
          source: 'AuthTokenService.issueTokenPair',
          provider: 'mongodb',
          retryable: true,
          entityType: 'user',
          entityId: user.id,
          userId: user.id,
          actorId: user.id,
        },
      );
    }

    const refreshPayload = this.buildRefreshTokenPayload(
      rotatedUser,
      refreshTokenId,
    );

    const refreshToken = this.jwtService.sign(refreshPayload, {
      secret: this.configService.getOrThrow<string>(
        AUTH_ENV.REFRESH_JWT_SECRET,
      ),
      expiresIn: this.configService.getOrThrow<StringValue>(
        AUTH_ENV.REFRESH_TOKEN_EXPIRES_IN,
      ),
    });

    return {
      user: rotatedUser,
      accessToken: this.issueAccessToken(rotatedUser),
      refreshToken,
    };
  }

  async refreshTokenPair(refreshToken: string): Promise<IssuedTokenPair> {
    try {
      const payload = await this.jwtService.verifyAsync<RefreshTokenPayload>(
        refreshToken,
        {
          secret: this.configService.getOrThrow<string>(
            AUTH_ENV.REFRESH_JWT_SECRET,
          ),
        },
      );

      if (payload.type !== 'refresh') {
        throw new AppError(
          APP_ERROR_CODES.AUTH_REFRESH_TOKEN_INVALID_TYPE,
          undefined,
          { tokenType: payload.type },
          {
            domain: 'auth',
            layer: 'service',
            kind: 'business',
            source: 'AuthTokenService.refreshTokenPair',
            provider: 'jwt',
            retryable: false,
          },
        );
      }

      const user = await this.usersService.findById(payload.sub);
      if (!user) {
        throw new AppError(
          APP_ERROR_CODES.AUTH_REFRESH_USER_NOT_FOUND,
          undefined,
          { userId: payload.sub },
          {
            domain: 'auth',
            layer: 'repository',
            kind: 'infrastructure',
            source: 'AuthTokenService.refreshTokenPair',
            provider: 'mongodb',
            retryable: false,
            entityType: 'user',
            entityId: payload.sub,
            userId: payload.sub,
          },
        );
      }

      if (
        user.tokenVersion !== payload.tokenVersion ||
        user.refreshTokenVersion !== payload.refreshTokenVersion ||
        user.currentRefreshTokenId !== payload.jti
      ) {
        throw new AppError(
          APP_ERROR_CODES.AUTH_REFRESH_TOKEN_REVOKED,
          undefined,
          {
            userId: user.id,
            tokenVersion: payload.tokenVersion,
            refreshTokenVersion: payload.refreshTokenVersion,
          },
          {
            domain: 'auth',
            layer: 'service',
            kind: 'business',
            source: 'AuthTokenService.refreshTokenPair',
            provider: 'jwt',
            retryable: false,
            entityType: 'user',
            entityId: user.id,
            userId: user.id,
          },
        );
      }

      return this.issueTokenPair(user);
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }

      throw new AppError(
        APP_ERROR_CODES.AUTH_REFRESH_TOKEN_INVALID_OR_EXPIRED,
        undefined,
        undefined,
        {
          domain: 'auth',
          layer: 'service',
          kind: 'integration',
          source: 'AuthTokenService.refreshTokenPair',
          provider: 'jwt',
          retryable: false,
        },
        error,
      );
    }
  }

  async revokeAllTokens(userId: string): Promise<{ message: string }> {
    await this.usersService.revokeAuthSessions(userId);
    this.logger.infoEvent('auth_sessions_revoked', {
      message: 'All auth sessions revoked',
      user_id: userId,
      actor_id: userId,
      entity_type: 'user',
      entity_id: userId,
    });
    return { message: 'Đăng xuất thành công, token đã bị thu hồi.' };
  }
}

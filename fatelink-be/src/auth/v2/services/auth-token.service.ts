import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { AppError } from '../../../common/errors/app-error';
import { APP_ERROR_CODES } from '../../../common/errors/app-error-codes';
import { AppLoggerService } from '../../../common/logger/logger.service';
import { UserDocument } from '../../../users/schemas/user.schema';
import { UsersService } from '../../../users/users.service';
import { DeviceType } from '../dto/device-type.enum';
import {
  RefreshTokenStoreService,
  V2AuthUserSnapshot,
} from './refresh-token-store.service';

type IssuedTokenPair = {
  user: V2AuthUserSnapshot;
  accessToken: string;
  refreshToken: string;
};

@Injectable()
export class AuthTokenService {
  constructor(
    private readonly jwtService: JwtService,
    private readonly logger: AppLoggerService,
    private readonly usersService: UsersService,
    private readonly refreshTokenStoreService: RefreshTokenStoreService,
  ) {}

  issueAccessToken(user: V2AuthUserSnapshot, deviceType: DeviceType): string {
    const payload = {
      sub: user._id,
      email: user.email,
      tokenVersion: user.tokenVersion || 0,
      deviceType,
    };

    return this.jwtService.sign(payload, {
      expiresIn: '5m',
    });
  }

  private toAuthUserSnapshot(user: UserDocument): V2AuthUserSnapshot {
    return {
      _id: user.id,
      email: user.email,
      name: user.name,
      avatar: user.avatar,
      googleId: user.googleId,
      latestEmotion: user.latestEmotion,
      personality: user.personality,
      bio: user.bio,
      fcmToken: user.fcmToken,
      tokenVersion: user.tokenVersion ?? 0,
      refreshTokenVersion: user.refreshTokenVersion ?? 0,
      currentRefreshTokenId: user.currentRefreshTokenId ?? '',
    };
  }

  async issueTokenPair(
    user: UserDocument,
    deviceType: DeviceType,
  ): Promise<IssuedTokenPair> {
    const authUser = this.toAuthUserSnapshot(user);
    const refreshToken = await this.refreshTokenStoreService.issue(
      authUser,
      deviceType,
    );

    return {
      user: authUser,
      accessToken: this.issueAccessToken(authUser, deviceType),
      refreshToken,
    };
  }

  async refreshTokenPair(refreshToken: string): Promise<IssuedTokenPair> {
    try {
      const rotated = await this.refreshTokenStoreService.rotate(refreshToken);
      if (!rotated) {
        throw new AppError(
          APP_ERROR_CODES.AUTH_REFRESH_TOKEN_REVOKED,
          undefined,
          {
            domain: 'auth',
            layer: 'service',
            kind: 'business',
            source: 'AuthTokenService.refreshTokenPair',
            provider: 'redis',
            retryable: false,
          },
        );
      }

      return {
        user: rotated.session.user,
        accessToken: this.issueAccessToken(
          rotated.session.user,
          rotated.session.deviceType,
        ),
        refreshToken: rotated.refreshToken,
      };
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
          provider: 'redis',
          retryable: false,
        },
        error,
      );
    }
  }

  async revokeAllTokens(
    userId: string,
    deviceType?: DeviceType,
  ): Promise<{ message: string }> {
    await this.refreshTokenStoreService.revokeByUserId(userId, deviceType);
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

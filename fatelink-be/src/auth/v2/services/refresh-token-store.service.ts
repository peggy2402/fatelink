import {
  Injectable,
  InternalServerErrorException,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import ms, { StringValue } from 'ms';
import { randomUUID } from 'crypto';
import { createClient } from 'redis';
import { AUTH_ENV } from '../../shared/auth.constants';
import { DeviceType } from '../dto/device-type.enum';

export type V2AuthUserSnapshot = {
  _id: string;
  email: string;
  name: string;
  avatar: string;
  googleId: string;
  latestEmotion: string;
  personality: number[];
  bio: string;
  fcmToken: string;
  tokenVersion: number;
  refreshTokenVersion: number;
  currentRefreshTokenId: string;
};

export type RefreshTokenSessionRecord = {
  deviceType: DeviceType;
  user: V2AuthUserSnapshot;
};

type RotatedRefreshTokenResult = {
  refreshToken: string;
  session: RefreshTokenSessionRecord;
};

@Injectable()
export class RefreshTokenStoreService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RefreshTokenStoreService.name);
  private readonly tokenKeyPrefix = 'auth:v2:refresh:token:';
  private readonly userKeyPrefix = 'auth:v2:refresh:user:';
  private redisClient: ReturnType<typeof createClient> | null = null;

  constructor(private readonly configService: ConfigService) {}

  async onModuleInit(): Promise<void> {
    const redisUrl = this.configService.get<string>('REDIS_URL');
    if (!redisUrl) {
      this.logger.warn(
        'REDIS_URL chưa được cấu hình. V2 opaque refresh token sẽ không hoạt động.',
      );
      return;
    }

    const client = createClient({
      url: redisUrl,
      socket: {
        connectTimeout: 5000,
      },
    });

    client.on('error', (error: unknown) => {
      const errorMessage =
        error instanceof Error ? error.message : 'unknown error';
      this.logger.warn(`Refresh token store Redis error: ${errorMessage}`);
    });

    try {
      await client.connect();
      this.redisClient = client;
      this.logger.log('Redis refresh token store đã được kết nối.');
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'unknown error';
      this.logger.warn(
        `Không thể kết nối Redis refresh token store. Lỗi: ${errorMessage}`,
      );
      await client.disconnect().catch(() => undefined);
    }
  }

  async onModuleDestroy(): Promise<void> {
    if (this.redisClient?.isOpen) {
      await this.redisClient.quit().catch(() => undefined);
    }
  }

  async issue(
    user: V2AuthUserSnapshot,
    deviceType: DeviceType,
  ): Promise<string> {
    const client = this.ensureClient();
    const ttlSeconds = this.getRefreshTokenTtlSeconds();
    const userKey = this.buildUserKey(user._id, deviceType);
    const existingToken = await client.get(userKey);
    const refreshToken = randomUUID();

    const transaction = client.multi();
    if (existingToken) {
      transaction.del(this.buildTokenKey(existingToken));
    }

    transaction.set(
      this.buildTokenKey(refreshToken),
      JSON.stringify({ deviceType, user } satisfies RefreshTokenSessionRecord),
      { EX: ttlSeconds },
    );
    transaction.set(userKey, refreshToken, { EX: ttlSeconds });
    await transaction.exec();

    return refreshToken;
  }

  async rotate(
    currentRefreshToken: string,
  ): Promise<RotatedRefreshTokenResult | null> {
    const client = this.ensureClient();
    const session = await this.getSession(currentRefreshToken);
    if (!session) {
      return null;
    }

    const tokenKey = this.buildTokenKey(currentRefreshToken);
    const userKey = this.buildUserKey(session.user._id, session.deviceType);
    const ttlSeconds = this.getRefreshTokenTtlSeconds();
    const nextRefreshToken = randomUUID();

    await client.watch([tokenKey, userKey]);

    try {
      const currentTokenPayload = await client.get(tokenKey);
      const currentUserToken = await client.get(userKey);

      if (!currentTokenPayload || currentUserToken !== currentRefreshToken) {
        return null;
      }

      const transaction = client.multi();
      transaction.del(tokenKey);
      transaction.set(
        this.buildTokenKey(nextRefreshToken),
        JSON.stringify(session),
        { EX: ttlSeconds },
      );
      transaction.set(userKey, nextRefreshToken, { EX: ttlSeconds });

      const result = await transaction.exec();
      if (result === null) {
        return null;
      }

      return {
        refreshToken: nextRefreshToken,
        session,
      };
    } finally {
      await client.unwatch();
    }
  }

  async revokeByUserId(userId: string, deviceType?: DeviceType): Promise<void> {
    if (deviceType) {
      await this.revokeByUserAndDevice(userId, deviceType);
      return;
    }

    await this.revokeByUserAndDevice(userId, DeviceType.WEB);
    await this.revokeByUserAndDevice(userId, DeviceType.DESKTOP);
    await this.revokeByUserAndDevice(userId, DeviceType.MOBILE);
  }

  private async revokeByUserAndDevice(
    userId: string,
    deviceType: DeviceType,
  ): Promise<void> {
    const client = this.ensureClient();
    const currentRefreshToken = await client.get(
      this.buildUserKey(userId, deviceType),
    );
    if (!currentRefreshToken) {
      await client.del(this.buildUserKey(userId, deviceType));
      return;
    }

    const transaction = client.multi();
    transaction.del(this.buildTokenKey(currentRefreshToken));
    transaction.del(this.buildUserKey(userId, deviceType));
    await transaction.exec();
  }

  async getSession(
    refreshToken: string,
  ): Promise<RefreshTokenSessionRecord | null> {
    const client = this.ensureClient();
    const value = await client.get(this.buildTokenKey(refreshToken));
    if (!value) {
      return null;
    }

    return JSON.parse(value) as RefreshTokenSessionRecord;
  }

  private ensureClient(): ReturnType<typeof createClient> {
    if (!this.redisClient?.isOpen) {
      throw new InternalServerErrorException(
        'Redis refresh token store chưa sẵn sàng.',
      );
    }

    return this.redisClient;
  }

  private getRefreshTokenTtlSeconds(): number {
    const refreshExpiresIn = this.configService.getOrThrow<StringValue>(
      AUTH_ENV.REFRESH_TOKEN_EXPIRES_IN,
    );
    const durationMs = ms(refreshExpiresIn);

    if (typeof durationMs !== 'number' || durationMs <= 0) {
      throw new InternalServerErrorException(
        'REFRESH_TOKEN_EXPIRES_IN không hợp lệ.',
      );
    }

    return Math.ceil(durationMs / 1000);
  }

  private buildTokenKey(refreshToken: string): string {
    return `${this.tokenKeyPrefix}${refreshToken}`;
  }

  private buildUserKey(userId: string, deviceType: DeviceType): string {
    return `${this.userKeyPrefix}${userId}:${deviceType}`;
  }
}

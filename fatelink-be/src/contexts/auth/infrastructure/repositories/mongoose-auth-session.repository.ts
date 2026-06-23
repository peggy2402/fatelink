import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import type {
  AuthSessionRecord,
  AuthSessionRepository,
} from '@contexts/auth/domain/repositories/auth-session.repository';
import { AUTH_SESSION_STATUS } from '@contexts/auth/domain/repositories/auth-session.repository';
import { Model } from 'mongoose';
import { AuthSession, AuthSessionDocument } from '../models/auth-session.model';

@Injectable()
export class MongooseAuthSessionRepository implements AuthSessionRepository {
  constructor(
    @InjectModel(AuthSession.name)
    private readonly authSessionModel: Model<AuthSessionDocument>,
  ) {}

  async create(input: {
    sessionId: string;
    userId: string;
    deviceType: string;
    deviceId: string;
    refreshTokenHash: string;
    ipAddress?: string;
    userAgent?: string;
  }): Promise<AuthSessionRecord> {
    const now = new Date();
    await this.authSessionModel
      .updateMany(
        {
          userId: input.userId,
          deviceId: input.deviceId,
          status: AUTH_SESSION_STATUS.ACTIVE,
        },
        {
          $set: {
            status: AUTH_SESSION_STATUS.REVOKED,
            revokedAt: now,
            revokedReason: 'device_relogin',
            lastSeenAt: now,
          },
        },
      )
      .exec();
    const document = await this.authSessionModel.create({
      ...input,
      status: AUTH_SESSION_STATUS.ACTIVE,
      lastRefreshedAt: now,
      lastSeenAt: now,
    });
    return this.toRecord(document);
  }

  async findActiveBySessionId(
    sessionId: string,
  ): Promise<AuthSessionRecord | null> {
    const document = await this.authSessionModel
      .findOne({ sessionId, status: AUTH_SESSION_STATUS.ACTIVE })
      .exec();
    return document ? this.toRecord(document) : null;
  }

  async findActiveByRefreshTokenHash(
    refreshTokenHash: string,
  ): Promise<AuthSessionRecord | null> {
    const document = await this.authSessionModel
      .findOne({ refreshTokenHash, status: AUTH_SESSION_STATUS.ACTIVE })
      .exec();
    return document ? this.toRecord(document) : null;
  }

  async findBySessionId(sessionId: string): Promise<AuthSessionRecord | null> {
    const document = await this.authSessionModel.findOne({ sessionId }).exec();
    return document ? this.toRecord(document) : null;
  }

  async findByUserId(userId: string): Promise<AuthSessionRecord[]> {
    const documents = await this.authSessionModel
      .find({ userId })
      .sort({ createdAt: -1 })
      .exec();
    return documents.map((document) => this.toRecord(document));
  }

  async rotate(input: {
    currentSessionId: string;
    currentRefreshTokenHash: string;
    nextRefreshTokenHash: string;
    deviceType: string;
    deviceId: string;
    ipAddress?: string;
    userAgent?: string;
  }): Promise<AuthSessionRecord | null> {
    const now = new Date();
    const current = await this.authSessionModel
      .findOneAndUpdate(
        {
          sessionId: input.currentSessionId,
          status: AUTH_SESSION_STATUS.ACTIVE,
          refreshTokenHash: input.currentRefreshTokenHash,
        },
        {
          $set: {
            refreshTokenHash: input.nextRefreshTokenHash,
            deviceType: input.deviceType,
            deviceId: input.deviceId,
            ipAddress: input.ipAddress,
            userAgent: input.userAgent,
            lastRefreshedAt: now,
            lastSeenAt: now,
            revokedAt: undefined,
            revokedReason: undefined,
            replacedBySessionId: undefined,
          },
        },
        { new: true },
      )
      .exec();

    return current ? this.toRecord(current) : null;
  }

  async touch(sessionId: string): Promise<void> {
    await this.authSessionModel
      .updateOne(
        { sessionId, status: AUTH_SESSION_STATUS.ACTIVE },
        { $set: { lastSeenAt: new Date() } },
      )
      .exec();
  }

  async revokeBySessionId(sessionId: string, reason = 'logout'): Promise<void> {
    const now = new Date();
    await this.authSessionModel
      .updateOne(
        { sessionId, status: AUTH_SESSION_STATUS.ACTIVE },
        {
          $set: {
            status: AUTH_SESSION_STATUS.REVOKED,
            revokedAt: now,
            revokedReason: reason,
            lastSeenAt: now,
          },
        },
      )
      .exec();
  }

  private toRecord(document: AuthSessionDocument): AuthSessionRecord {
    const plainRecord = document.toObject();

    return {
      sessionId: plainRecord.sessionId,
      userId: plainRecord.userId,
      deviceType: plainRecord.deviceType,
      deviceId: plainRecord.deviceId,
      refreshTokenHash: plainRecord.refreshTokenHash,
      status: plainRecord.status,
      ipAddress: plainRecord.ipAddress,
      userAgent: plainRecord.userAgent,
      createdAt: plainRecord.createdAt,
      lastRefreshedAt: plainRecord.lastRefreshedAt,
      lastSeenAt: plainRecord.lastSeenAt,
      revokedAt: plainRecord.revokedAt,
      revokedReason: plainRecord.revokedReason,
      replacedBySessionId: plainRecord.replacedBySessionId,
    };
  }
}

import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import type {
  AuthChallengeRecord,
  AuthChallengeRepository,
} from '@contexts/auth/domain/repositories/auth-challenge.repository';
import { Model } from 'mongoose';
import {
  AuthChallenge,
  AuthChallengeDocument,
} from '../models/auth-challenge.model';

@Injectable()
export class MongooseAuthChallengeRepository implements AuthChallengeRepository {
  constructor(
    @InjectModel(AuthChallenge.name)
    private readonly authChallengeModel: Model<AuthChallengeDocument>,
  ) {}

  async save(input: AuthChallengeRecord): Promise<AuthChallengeRecord> {
    const record = await this.authChallengeModel
      .findOneAndUpdate(
        { type: input.type, key: input.key },
        {
          $set: {
            secretHash: input.secretHash,
            expiresAt: input.expiresAt,
            attemptCount: input.attemptCount ?? 0,
            metadata: input.metadata || {},
            lockedAt: undefined,
          },
          $setOnInsert: {
            maxAttempts: input.maxAttempts ?? 5,
          },
        },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      )
      .exec();
    return this.toRecord(record);
  }

  async find(
    type: AuthChallengeRecord['type'],
    key: string,
  ): Promise<AuthChallengeRecord | null> {
    const record = await this.authChallengeModel.findOne({ type, key }).exec();
    return record ? this.toRecord(record) : null;
  }

  async registerFailedAttempt(
    type: AuthChallengeRecord['type'],
    key: string,
  ): Promise<AuthChallengeRecord | null> {
    const current = await this.authChallengeModel.findOne({ type, key }).exec();
    if (!current) {
      return null;
    }

    const nextAttemptCount = (current.attemptCount || 0) + 1;
    const shouldLock = nextAttemptCount >= (current.maxAttempts || 5);
    const record = await this.authChallengeModel
      .findOneAndUpdate(
        { type, key },
        {
          $set: {
            attemptCount: nextAttemptCount,
            lockedAt: shouldLock ? new Date() : undefined,
          },
        },
        { new: true },
      )
      .exec();

    return record ? this.toRecord(record) : null;
  }

  async consumeMagicLink(
    key: string,
    tokenDigest: string,
  ): Promise<AuthChallengeRecord | null> {
    const record = await this.authChallengeModel
      .findOneAndDelete({
        type: 'magic_link',
        key,
        expiresAt: { $gte: new Date() },
        $or: [{ lockedAt: null }, { lockedAt: { $exists: false } }],
        'metadata.tokenDigest': tokenDigest,
      })
      .exec();

    return record ? this.toRecord(record) : null;
  }

  async consume(type: AuthChallengeRecord['type'], key: string): Promise<void> {
    await this.authChallengeModel.deleteOne({ type, key }).exec();
  }

  private toRecord(document: AuthChallengeDocument): AuthChallengeRecord {
    const plainRecord = document.toObject();

    return {
      type: plainRecord.type,
      key: plainRecord.key,
      secretHash: plainRecord.secretHash,
      expiresAt: plainRecord.expiresAt,
      attemptCount: plainRecord.attemptCount,
      maxAttempts: plainRecord.maxAttempts,
      lockedAt: plainRecord.lockedAt,
      metadata: plainRecord.metadata
        ? { ...plainRecord.metadata }
        : undefined,
    };
  }
}

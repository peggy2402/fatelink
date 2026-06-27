import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import type {
  AuthIdentityRecord,
  AuthIdentityRepository,
} from '@contexts/auth/domain/repositories/auth-identity.repository';
import { Model } from 'mongoose';
import {
  AuthIdentity,
  AuthIdentityDocument,
} from '../models/auth-identity.model';

@Injectable()
export class MongooseAuthIdentityRepository implements AuthIdentityRepository {
  constructor(
    @InjectModel(AuthIdentity.name)
    private readonly authIdentityModel: Model<AuthIdentityDocument>,
  ) {}

  async findByProvider(
    provider: AuthIdentityRecord['provider'],
    providerUserId: string,
  ): Promise<AuthIdentityRecord | null> {
    const record = await this.authIdentityModel
      .findOne({ provider, providerUserId })
      .exec();
    return record ? this.toRecord(record) : null;
  }

  async upsertEmailCredential(input: {
    userId: string;
    email: string;
    passwordHash: string;
  }): Promise<AuthIdentityRecord> {
    const record = await this.authIdentityModel
      .findOneAndUpdate(
        { provider: 'email', providerUserId: input.email },
        {
          $set: {
            userId: input.userId,
            providerEmail: input.email,
            secretHash: input.passwordHash,
          },
        },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      )
      .exec();
    return this.toRecord(record);
  }

  async linkFacebookIdentity(input: {
    userId: string;
    facebookId: string;
    email?: string;
  }): Promise<AuthIdentityRecord> {
    const record = await this.authIdentityModel
      .findOneAndUpdate(
        { provider: 'facebook', providerUserId: input.facebookId },
        {
          $set: {
            userId: input.userId,
            providerEmail: input.email,
          },
        },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      )
      .exec();
    return this.toRecord(record);
  }

  async linkGoogleIdentity(input: {
    userId: string;
    googleId: string;
    email?: string;
  }): Promise<AuthIdentityRecord> {
    const record = await this.authIdentityModel
      .findOneAndUpdate(
        { provider: 'google', providerUserId: input.googleId },
        {
          $set: {
            userId: input.userId,
            providerEmail: input.email,
          },
        },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      )
      .exec();
    return this.toRecord(record);
  }

  async linkZaloIdentity(input: {
    userId: string;
    zaloId: string;
    email?: string;
  }): Promise<AuthIdentityRecord> {
    const record = await this.authIdentityModel
      .findOneAndUpdate(
        { provider: 'zalo', providerUserId: input.zaloId },
        {
          $set: {
            userId: input.userId,
            providerEmail: input.email,
          },
        },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      )
      .exec();
    return this.toRecord(record);
  }

  async linkTikTokIdentity(input: {
    userId: string;
    tikTokId: string;
    email?: string;
  }): Promise<AuthIdentityRecord> {
    const record = await this.authIdentityModel
      .findOneAndUpdate(
        { provider: 'tiktok', providerUserId: input.tikTokId },
        {
          $set: {
            userId: input.userId,
            providerEmail: input.email,
          },
        },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      )
      .exec();
    return this.toRecord(record);
  }

  async linkPhoneIdentity(input: {
    userId: string;
    phoneNumber: string;
  }): Promise<AuthIdentityRecord> {
    const record = await this.authIdentityModel
      .findOneAndUpdate(
        { provider: 'phone', providerUserId: input.phoneNumber },
        {
          $set: {
            userId: input.userId,
          },
        },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      )
      .exec();
    return this.toRecord(record);
  }

  private toRecord(document: AuthIdentityDocument): AuthIdentityRecord {
    const plainRecord = document.toObject();

    return {
      userId: plainRecord.userId,
      provider: plainRecord.provider,
      providerUserId: plainRecord.providerUserId,
      providerEmail: plainRecord.providerEmail,
      secretHash: plainRecord.secretHash,
    };
  }
}

import { User as DomainUser } from '@contexts/users/domain/entities/user';
import { UserAccountProfile } from '@contexts/users/domain/entities/user-account-profile';
import type { UserRepository as UserRepositoryPort } from '@contexts/users/domain/repositories/user.repository';
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { HydratedDocument, Model } from 'mongoose';
import { User, UserDocument } from '../models/user.model';

@Injectable()
export class MongooseUserRepository implements UserRepositoryPort {
  constructor(
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
  ) {}

  async createProfileAccount(profile: UserAccountProfile): Promise<DomainUser> {
    const user = await this.userModel.create({
      email: profile.email,
      name: profile.name,
      avatar: profile.avatar,
    });
    return this.toDomainUser(user);
  }

  async findById(userId: string): Promise<DomainUser | null> {
    const user = await this.userModel.findById(userId).exec();
    return user ? this.toDomainUser(user) : null;
  }

  async findByEmail(email: string): Promise<DomainUser | null> {
    const user = await this.userModel.findOne({ email }).exec();
    return user ? this.toDomainUser(user) : null;
  }

  async updateTraits(
    userId: string,
    emotions: Record<string, number>,
    personality: number[],
    latestEmotion: string,
  ): Promise<void> {
    await this.userModel.findByIdAndUpdate(userId, {
      emotions,
      personality,
      latestEmotion,
    });
  }

  async findMatches(userId: string): Promise<DomainUser[]> {
    const user = await this.userModel.findById(userId).exec();
    if (!user || !user.latestEmotion) {
      return [];
    }

    const matches = await this.userModel
      .find({
        _id: { $ne: userId },
        latestEmotion: user.latestEmotion,
      })
      .limit(20)
      .exec();
    return matches.map((item) => this.toDomainUser(item));
  }

  async findAllExcept(userId: string): Promise<DomainUser[]> {
    const users = await this.userModel.find({ _id: { $ne: userId } }).exec();
    return users.map((item) => this.toDomainUser(item));
  }

  async updateFcmToken(
    userId: string,
    fcmToken: string,
  ): Promise<DomainUser | null> {
    return this.userModel
      .findByIdAndUpdate(userId, { fcmToken }, { new: true })
      .exec()
      .then((item) => (item ? this.toDomainUser(item) : null));
  }

  async updateFrequency(
    userId: string,
    data: {
      latestEmotion: string;
      moodIcon: string;
      frequencyHertz: string;
      desiredVibe: string;
      tags: string[];
      emotions: Record<string, number>;
    },
  ): Promise<DomainUser | null> {
    const updated = await this.userModel
      .findByIdAndUpdate(
        userId,
        {
          latestEmotion: data.latestEmotion,
          moodIcon: data.moodIcon,
          frequencyHertz: data.frequencyHertz,
          desiredVibe: data.desiredVibe,
          tags: data.tags,
          emotions: data.emotions,
        },
        { new: true },
      )
      .exec();
    return updated ? this.toDomainUser(updated) : null;
  }

  async findAll(): Promise<DomainUser[]> {
    const users = await this.userModel.find().sort({ createdAt: -1 }).exec();
    return users.map((item) => this.toDomainUser(item));
  }

  async banUser(userId: string, isBanned: boolean): Promise<DomainUser | null> {
    return this.userModel
      .findByIdAndUpdate(userId, { isBanned }, { new: true })
      .exec()
      .then((item) => (item ? this.toDomainUser(item) : null));
  }

  async updateProfile(
    userId: string,
    data: {
      name?: string;
      handle?: string;
      avatar?: string;
      bio?: string;
      gender?: string;
      dateOfBirth?: string;
      address?: string;
      isFaceLocked?: boolean;
      vibePhotos?: {
        id: string;
        imageUrl: string;
        createdAt?: Date;
        durationMinutes?: number;
        expiresAt: Date;
      }[];
    },
  ): Promise<DomainUser | null> {
    const updateData: Record<string, any> = {};
    if (data.name !== undefined) updateData.name = data.name;
    if (data.handle !== undefined) updateData.handle = data.handle;
    if (data.avatar !== undefined) updateData.avatar = data.avatar;
    if (data.bio !== undefined) updateData.bio = data.bio;
    if (data.gender !== undefined) updateData.gender = data.gender;
    if (data.dateOfBirth !== undefined) updateData.dateOfBirth = data.dateOfBirth;
    if (data.address !== undefined) updateData.address = data.address;
    if (data.isFaceLocked !== undefined) updateData.isFaceLocked = data.isFaceLocked;
    if (data.vibePhotos !== undefined) {
      const now = new Date();
      updateData.vibePhotos = data.vibePhotos.filter(
        (p) => new Date(p.expiresAt) > now,
      );
    }

    const updated = await this.userModel
      .findByIdAndUpdate(userId, { $set: updateData }, { new: true })
      .exec();
    return updated ? this.toDomainUser(updated) : null;
  }

  private toDomainUser(document: HydratedDocument<User>): DomainUser {
    const plainUser = document.toObject();
    const now = new Date();
    const activeVibes = ((plainUser as any).vibePhotos || [])
      .filter((v: any) => new Date(v.expiresAt) > now)
      .map((v: any) => ({
        id: v.id,
        imageUrl: v.imageUrl,
        createdAt: new Date(v.createdAt),
        durationMinutes: v.durationMinutes,
        expiresAt: new Date(v.expiresAt),
      }));

    return DomainUser.rehydrate({
      id: document._id.toString(),
      email: plainUser.email,
      handle: (plainUser as any).handle,
      name: plainUser.name,
      avatar: plainUser.avatar,
      bio: plainUser.bio,
      gender: (plainUser as any).gender,
      dateOfBirth: (plainUser as any).dateOfBirth,
      address: (plainUser as any).address,
      isFaceLocked: (plainUser as any).isFaceLocked ?? false,
      vibePhotos: activeVibes,
      latestEmotion: plainUser.latestEmotion,
      emotions: { ...plainUser.emotions },
      personality: [...plainUser.personality],
      fcmToken: plainUser.fcmToken,
      tags: plainUser.tags ? [...plainUser.tags] : [],
      frequencyHertz: plainUser.frequencyHertz,
      moodIcon: plainUser.moodIcon,
      desiredVibe: plainUser.desiredVibe,
    });
  }
}

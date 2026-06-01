import { User as DomainUser } from '@contexts/users/domain/entities/user';
import { UserProfile } from '@contexts/users/domain/entities/user-profile';
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

  async findOrCreate(profile: UserProfile): Promise<DomainUser> {
    const user = await this.userModel
      .findOneAndUpdate(
        { email: profile.email },
        {
          $set: {
            name: profile.name,
            avatar: profile.avatar,
          },
          $setOnInsert: {
            email: profile.email,
            googleId: profile.googleId,
          },
        },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      )
      .exec();
    return this.toDomainUser(user);
  }

  async findById(userId: string): Promise<DomainUser | null> {
    const user = await this.userModel.findById(userId).exec();
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

  async incrementTokenVersion(userId: string): Promise<DomainUser | null> {
    return this.userModel
      .findByIdAndUpdate(userId, {
        $inc: { tokenVersion: 1 },
      })
      .exec()
      .then((item) => (item ? this.toDomainUser(item) : null));
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

  private toDomainUser(document: HydratedDocument<User>): DomainUser {
    return DomainUser.rehydrate({
      id: document._id.toString(),
      email: document.email,
      name: document.name,
      avatar: document.avatar,
      googleId: document.googleId,
      latestEmotion: document.latestEmotion,
      emotions: { ...document.emotions },
      personality: [...document.personality],
      bio: document.bio,
      fcmToken: document.fcmToken,
      tokenVersion: document.tokenVersion,
    });
  }
}

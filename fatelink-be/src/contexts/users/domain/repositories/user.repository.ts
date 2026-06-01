import { type UserProfile } from '@contexts/users/domain/entities/user-profile';
import { type User } from '@contexts/users/domain/entities/user';

export interface UserRepository {
  findOrCreate(profile: UserProfile): Promise<User>;
  findById(userId: string): Promise<User | null>;
  updateTraits(
    userId: string,
    emotions: Record<string, number>,
    personality: number[],
    latestEmotion: string,
  ): Promise<void>;
  findMatches(userId: string): Promise<User[]>;
  findAllExcept(userId: string): Promise<User[]>;
  updateFcmToken(userId: string, fcmToken: string): Promise<User | null>;
  incrementTokenVersion(userId: string): Promise<User | null>;
  findAll(): Promise<User[]>;
  banUser(userId: string, isBanned: boolean): Promise<User | null>;
}

import { type UserAccountProfile } from '@contexts/users/domain/entities/user-account-profile';
import { type User } from '@contexts/users/domain/entities/user';

export interface UserRepository {
  findById(userId: string): Promise<User | null>;
  findByEmail(email: string): Promise<User | null>;
  createProfileAccount(profile: UserAccountProfile): Promise<User>;
  updateTraits(
    userId: string,
    emotions: Record<string, number>,
    personality: number[],
    latestEmotion: string,
  ): Promise<void>;
  findMatches(userId: string): Promise<User[]>;
  findAllExcept(userId: string): Promise<User[]>;
  updateFcmToken(userId: string, fcmToken: string): Promise<User | null>;
  findAll(): Promise<User[]>;
  banUser(userId: string, isBanned: boolean): Promise<User | null>;
}

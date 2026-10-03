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
  updateFrequency(
    userId: string,
    data: {
      latestEmotion: string;
      moodIcon: string;
      frequencyHertz: string;
      desiredVibe: string;
      tags: string[];
      emotions: Record<string, number>;
    },
  ): Promise<User | null>;
  findAll(): Promise<User[]>;
  banUser(userId: string, isBanned: boolean): Promise<User | null>;
  updateProfile(
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
  ): Promise<User | null>;
  recordProfileView(
    targetUserId: string,
    viewerId: string,
  ): Promise<{ profileViews: number }>;
  toggleLike(
    targetUserId: string,
    likerId: string,
  ): Promise<{ likesReceived: number; isLiked: boolean; isMutual: boolean }>;
  recordWave(
    targetUserId: string,
    senderId: string,
  ): Promise<{ wavesReceived: number }>;
  getNotifications(userId: string): Promise<any[]>;
  markNotificationAsRead(
    userId: string,
    notificationId: string,
  ): Promise<boolean>;
  markAllNotificationsAsRead(userId: string): Promise<boolean>;
  blockUser(userId: string, targetUserId: string): Promise<boolean>;
  unblockUser(userId: string, targetUserId: string): Promise<boolean>;
  getBlockedUsers(userId: string): Promise<User[]>;
  createReport(data: {
    reporterId: string;
    targetUserId: string;
    reason: string;
    details?: string;
  }): Promise<boolean>;
}

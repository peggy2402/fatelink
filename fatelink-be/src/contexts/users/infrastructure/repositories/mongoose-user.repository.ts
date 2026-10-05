import { User as DomainUser } from '@contexts/users/domain/entities/user';
import { UserAccountProfile } from '@contexts/users/domain/entities/user-account-profile';
import type { UserRepository as UserRepositoryPort } from '@contexts/users/domain/repositories/user.repository';
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { HydratedDocument, Model, Types } from 'mongoose';
import { User, UserDocument } from '../models/user.model';
import {
  Notification,
  NotificationDocument,
} from '../models/notification.model';
import { Report, ReportDocument } from '../models/report.model';

@Injectable()
export class MongooseUserRepository implements UserRepositoryPort {
  constructor(
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    @InjectModel(Notification.name)
    private readonly notificationModel: Model<NotificationDocument>,
    @InjectModel(Report.name)
    private readonly reportModel: Model<ReportDocument>,
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
    if (!Types.ObjectId.isValid(userId)) {
      return [];
    }

    const user = await this.userModel.findById(userId).exec();
    if (!user) {
      return [];
    }

    const liked = user.likedUsers || [];
    const blocked = user.blockedUsers || [];
    if (liked.length === 0) {
      return [];
    }

    // Những người mà user đã thích VÀ họ cũng thích lại user này (Mutual Match)
    // Đồng thời loại trừ những ai nằm trong danh sách chặn ở 2 chiều
    const matches = await this.userModel
      .find({
        _id: { $in: liked, $nin: blocked },
        likedUsers: userId,
        blockedUsers: { $ne: userId },
      })
      .exec();

    return matches.map((item) => this.toDomainUser(item));
  }

  async findAllExcept(userId: string): Promise<DomainUser[]> {
    if (!Types.ObjectId.isValid(userId)) {
      const users = await this.userModel.find().limit(50).exec();
      return users.map((item) => this.toDomainUser(item));
    }

    const currentUser = await this.userModel.findById(userId).exec();
    const blockedList = currentUser?.blockedUsers || [];

    // Loại trừ: chính mình, những người mình đã chặn, và những người đã chặn mình
    const users = await this.userModel
      .find({
        _id: { $nin: [userId, ...blockedList] },
        blockedUsers: { $ne: userId },
      })
      .exec();

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
    if (data.dateOfBirth !== undefined)
      updateData.dateOfBirth = data.dateOfBirth;
    if (data.address !== undefined) updateData.address = data.address;
    if (data.isFaceLocked !== undefined)
      updateData.isFaceLocked = data.isFaceLocked;
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

  // --- TƯƠNG TÁC PROFILE & THÔNG BÁO THẬT ---

  async recordProfileView(
    targetUserId: string,
    viewerId: string,
  ): Promise<{ profileViews: number }> {
    if (!Types.ObjectId.isValid(targetUserId) || !Types.ObjectId.isValid(viewerId)) {
      return { profileViews: 1 };
    }

    const updated = await this.userModel
      .findByIdAndUpdate(
        targetUserId,
        { $inc: { profileViews: 1 } },
        { new: true },
      )
      .exec();

    // Nếu người xem khác chủ hồ sơ, lưu thông báo ở chế độ ẩn danh
    if (targetUserId !== viewerId) {
      await this.notificationModel.create({
        userId: targetUserId,
        senderId: viewerId,
        senderName: 'Một tâm hồn đồng điệu',
        senderAvatar: '',
        type: 'view_profile',
        title: 'Ai đó vừa ghé thăm tần số của bạn! ✨',
        message: 'Một tâm hồn đồng điệu vừa dừng chân ghé thăm hồ sơ và tần số cảm xúc của bạn.',
      });
    }

    return { profileViews: updated?.profileViews ?? 0 };
  }

  async toggleLike(
    targetUserId: string,
    likerId: string,
  ): Promise<{ likesReceived: number; isLiked: boolean; isMutual: boolean }> {
    if (!Types.ObjectId.isValid(targetUserId) || !Types.ObjectId.isValid(likerId)) {
      return { likesReceived: 1, isLiked: true, isMutual: false };
    }

    const liker = await this.userModel.findById(likerId).exec();
    const targetUser = await this.userModel.findById(targetUserId).exec();

    if (!liker || !targetUser) {
      return { likesReceived: 0, isLiked: false, isMutual: false };
    }

    const likedUsers = liker.likedUsers || [];
    const isAlreadyLiked = likedUsers.includes(targetUserId);

    if (isAlreadyLiked) {
      // Bỏ like
      await this.userModel.findByIdAndUpdate(likerId, {
        $pull: { likedUsers: targetUserId },
      });
      const updatedTarget = await this.userModel.findByIdAndUpdate(
        targetUserId,
        { $inc: { likesReceived: -1 } },
        { new: true },
      );
      const likesCount = Math.max(0, updatedTarget?.likesReceived ?? 0);
      return { likesReceived: likesCount, isLiked: false, isMutual: false };
    } else {
      // Thả tim mới
      await this.userModel.findByIdAndUpdate(likerId, {
        $addToSet: { likedUsers: targetUserId },
      });
      const updatedTarget = await this.userModel.findByIdAndUpdate(
        targetUserId,
        { $inc: { likesReceived: 1 } },
        { new: true },
      );

      // Kiểm tra có phải Mutual Like (cả 2 cùng thích nhau) không
      const targetLikedUsers = targetUser.likedUsers || [];
      const isMutual = targetLikedUsers.includes(likerId);

      if (isMutual) {
        // Cả 2 cùng thả tim -> Tạo thông báo Kết nối định mệnh cho cả hai
        await this.notificationModel.create({
          userId: targetUserId,
          senderId: likerId,
          senderName: liker.name,
          senderAvatar: liker.avatar,
          type: 'mutual_match',
          title: '✨ Định mệnh giao thoa! Cả hai đã thả tim nhau!',
          message: `Bạn và ${liker.name} đã cùng thả tim! Diện mạo đã được mở khóa. Hãy bắt đầu trò chuyện ngay!`,
        });

        await this.notificationModel.create({
          userId: likerId,
          senderId: targetUserId,
          senderName: targetUser.name,
          senderAvatar: targetUser.avatar,
          type: 'mutual_match',
          title: '✨ Định mệnh giao thoa! Cả hai đã thả tim nhau!',
          message: `Bạn và ${targetUser.name} đã cùng thả tim! Diện mạo đã được mở khóa. Hãy bắt đầu trò chuyện ngay!`,
        });
      } else {
        // Chỉ liker thả tim targetUser -> Giữ ẩn danh tuyệt đối cho đến khi mutual match
        await this.notificationModel.create({
          userId: targetUserId,
          senderId: likerId,
          senderName: 'Một tâm hồn đồng điệu',
          senderAvatar: '',
          type: 'like',
          title: 'Ai đó vừa thả tim bạn! 💕',
          message: 'Một tâm hồn đồng điệu vừa thả tim hồ sơ của bạn. Cùng thả tim lại để mở khóa diện mạo nhé!',
        });
      }

      return {
        likesReceived: updatedTarget?.likesReceived ?? 1,
        isLiked: true,
        isMutual,
      };
    }
  }

  async recordWave(
    targetUserId: string,
    senderId: string,
  ): Promise<{ wavesReceived: number }> {
    if (!Types.ObjectId.isValid(targetUserId) || !Types.ObjectId.isValid(senderId)) {
      return { wavesReceived: 1 };
    }

    const updated = await this.userModel
      .findByIdAndUpdate(
        targetUserId,
        { $inc: { wavesReceived: 1 } },
        { new: true },
      )
      .exec();

    if (targetUserId !== senderId) {
      await this.notificationModel.create({
        userId: targetUserId,
        senderId,
        senderName: 'Một tâm hồn đồng điệu',
        senderAvatar: '',
        type: 'wave',
        title: '🌊 Nhận được sóng rung cảm mới!',
        message: 'Một tâm hồn đồng điệu vừa phát sóng rung cảm hướng về bạn!',
      });
    }

    return { wavesReceived: updated?.wavesReceived ?? 0 };
  }

  async getNotifications(userId: string): Promise<any[]> {
    const list = await this.notificationModel
      .find({ userId })
      .sort({ createdAt: -1 })
      .limit(50)
      .exec();
    return list.map((item) => {
      const obj = item.toObject();
      if (obj.type !== 'mutual_match' && obj.type !== 'mutual_like') {
        obj.senderName = 'Một tâm hồn đồng điệu';
        obj.senderAvatar = '';
        if (obj.type === 'like') {
          obj.message =
            'Một tâm hồn đồng điệu vừa thả tim hồ sơ của bạn. Cùng thả tim lại để mở khóa diện mạo nhé!';
        } else if (obj.type === 'view_profile' || obj.type === 'view') {
          obj.message =
            'Một tâm hồn đồng điệu vừa dừng chân ghé thăm hồ sơ và tần số cảm xúc của bạn.';
        } else if (obj.type === 'wave') {
          obj.message =
            'Một tâm hồn đồng điệu vừa phát sóng rung cảm hướng về bạn!';
        }
      }
      return obj;
    });
  }

  async markNotificationAsRead(
    userId: string,
    notificationId: string,
  ): Promise<boolean> {
    const res = await this.notificationModel
      .updateOne({ _id: notificationId, userId }, { isRead: true })
      .exec();
    return res.modifiedCount > 0;
  }

  async markAllNotificationsAsRead(userId: string): Promise<boolean> {
    const res = await this.notificationModel
      .updateMany({ userId }, { isRead: true })
      .exec();
    return res.modifiedCount > 0;
  }

  async blockUser(userId: string, targetUserId: string): Promise<boolean> {
    if (!Types.ObjectId.isValid(userId) || !Types.ObjectId.isValid(targetUserId)) {
      return true;
    }
    // 1. Thêm targetUserId vào blockedUsers của userId và tự động gỡ like
    await this.userModel.findByIdAndUpdate(userId, {
      $addToSet: { blockedUsers: targetUserId },
      $pull: { likedUsers: targetUserId },
    });

    // 2. Phía targetUser cũng bị gỡ like userId
    await this.userModel.findByIdAndUpdate(targetUserId, {
      $pull: { likedUsers: userId },
    });

    return true;
  }

  async unblockUser(userId: string, targetUserId: string): Promise<boolean> {
    if (!Types.ObjectId.isValid(userId) || !Types.ObjectId.isValid(targetUserId)) {
      return true;
    }
    await this.userModel.findByIdAndUpdate(userId, {
      $pull: { blockedUsers: targetUserId },
    });
    return true;
  }

  async getBlockedUsers(userId: string): Promise<DomainUser[]> {
    if (!Types.ObjectId.isValid(userId)) {
      return [];
    }
    const user = await this.userModel.findById(userId).exec();
    if (!user || !user.blockedUsers || user.blockedUsers.length === 0) {
      return [];
    }
    const validBlockedIds = user.blockedUsers.filter((id) => Types.ObjectId.isValid(id));
    if (validBlockedIds.length === 0) return [];

    const blockedDocs = await this.userModel
      .find({ _id: { $in: validBlockedIds } })
      .exec();
    return blockedDocs.map((doc) => this.toDomainUser(doc));
  }

  async createReport(data: {
    reporterId: string;
    targetUserId: string;
    reason: string;
    details?: string;
  }): Promise<boolean> {
    await this.reportModel.create({
      reporterId: data.reporterId,
      targetUserId: data.targetUserId,
      reason: data.reason,
      details: data.details || '',
      status: 'pending',
    });
    return true;
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
      likesReceived: (plainUser as any).likesReceived ?? 0,
      profileViews: (plainUser as any).profileViews ?? 0,
      wavesReceived: (plainUser as any).wavesReceived ?? 0,
      likedUsers: (plainUser as any).likedUsers ? [...(plainUser as any).likedUsers] : [],
      blockedUsers: (plainUser as any).blockedUsers ? [...(plainUser as any).blockedUsers] : [],
    });
  }
}

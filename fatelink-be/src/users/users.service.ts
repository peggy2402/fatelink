import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User, UserDocument } from './schemas/user.schema';
import { CreateUserDto } from './dto/create-user.dto';

@Injectable()
export class UsersService {
  constructor(@InjectModel(User.name) private userModel: Model<UserDocument>) {}

  /**
   * Finds a user by their profile data (email). If not found, creates a new user.
   * @param profile - The user profile data from Google.
   * @returns The found or newly created user document.
   */
  async findOrCreate(profile: CreateUserDto): Promise<UserDocument> {
    const user = await this.userModel
      .findOneAndUpdate(
        { email: profile.email }, // Điều kiện tìm kiếm
        {
          // Dữ liệu sẽ được cập nhật nếu tìm thấy, hoặc tạo mới nếu không tìm thấy
          $set: {
            name: profile.name,
            avatar: profile.avatar,
          },
          $setOnInsert: {
            email: profile.email,
            googleId: profile.googleId,
          },
        },
        { upsert: true, new: true, setDefaultsOnInsert: true }, // Tùy chọn: upsert=tạo nếu không có, new=trả về document mới
      )
      .exec();
    return user;
  }

  /**
   * Lấy thông tin user bằng ID
   */
  async findById(userId: string): Promise<UserDocument | null> {
    return this.userModel.findById(userId).exec();
  }

  /**
   * Cập nhật tính cách và cảm xúc bằng thuật toán Exponential Moving Average (EMA)
   */
  async updateUserTraits(userId: string, newEmotions: any, newPersonality: number[], latestEmotionStr: string) {
    const user = await this.userModel.findById(userId).exec();
    if (!user) return;

    // Lấy dữ liệu hiện tại, nếu chưa có thì gán mặc định
    const currentEmotions = user.emotions || { stress: 5, loneliness: 5, sadness: 5, calmness: 5, warmth: 5, happiness: 5 };
    const currentPersonality = user.personality && user.personality.length === 3 ? user.personality : [5, 5, 5];

    // EMA Cảm xúc: 80% cũ, 20% mới
    const weightE = 0.2;
    const updatedEmotions = {
      stress: Math.round(currentEmotions.stress * (1 - weightE) + (newEmotions?.stress ?? currentEmotions.stress) * weightE),
      loneliness: Math.round(currentEmotions.loneliness * (1 - weightE) + (newEmotions?.loneliness ?? currentEmotions.loneliness) * weightE),
      sadness: Math.round(currentEmotions.sadness * (1 - weightE) + (newEmotions?.sadness ?? currentEmotions.sadness) * weightE),
      calmness: Math.round(currentEmotions.calmness * (1 - weightE) + (newEmotions?.calmness ?? currentEmotions.calmness) * weightE),
      warmth: Math.round(currentEmotions.warmth * (1 - weightE) + (newEmotions?.warmth ?? currentEmotions.warmth) * weightE),
      happiness: Math.round(currentEmotions.happiness * (1 - weightE) + (newEmotions?.happiness ?? currentEmotions.happiness) * weightE),
    };

    // EMA Tính cách: 90% cũ, 10% mới
    const weightP = 0.1;
    const updatedPersonality = [
      Math.round(currentPersonality[0] * (1 - weightP) + (newPersonality?.[0] ?? currentPersonality[0]) * weightP),
      Math.round(currentPersonality[1] * (1 - weightP) + (newPersonality?.[1] ?? currentPersonality[1]) * weightP),
      Math.round(currentPersonality[2] * (1 - weightP) + (newPersonality?.[2] ?? currentPersonality[2]) * weightP),
    ];

    // Lưu vào DB
    await this.userModel.findByIdAndUpdate(userId, {
      emotions: updatedEmotions,
      personality: updatedPersonality,
      latestEmotion: latestEmotionStr || user.latestEmotion,
    });
  }

  /**
   * Tìm danh sách người dùng có cùng tần số cảm xúc (Dùng để test nhanh)
   */
  async findMatches(userId: string): Promise<UserDocument[]> {
    const user = await this.userModel.findById(userId).exec();
    
    if (!user || !user.latestEmotion) {
      return []; 
    }

    return this.userModel.find({
      _id: { $ne: userId },
      latestEmotion: user.latestEmotion,
    }).limit(20).exec(); 
  }

  async updateFcmToken(userId: string, fcmToken: string) {
    return this.userModel.findByIdAndUpdate(
      userId, 
      { fcmToken }, 
      { new: true }
    ).exec();
  }

}
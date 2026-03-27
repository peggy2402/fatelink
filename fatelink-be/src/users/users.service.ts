import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User, UserDocument } from './schemas/user.schema';

@Injectable()
export class UsersService {
  constructor(@InjectModel(User.name) private userModel: Model<UserDocument>) {}

  /**
   * Finds a user by their profile data (email). If not found, creates a new user.
   * @param profile - The user profile data from Google.
   * @returns The found or newly created user document.
   */
  async findOrCreate(profile: {
    email: string;
    name?: string;
    avatar?: string;
    googleId: string;
  }): Promise<UserDocument> {
    const user = await this.userModel.findOne({ email: profile.email }).exec();

    if (user) {
      console.log('✅ User CŨ đăng nhập:', user.email);
      return user;
    }

    const newUser = await this.userModel.create(profile);
    console.log('✅ Đã lưu User MỚI vào MongoDB:', newUser.email);
    return newUser;
  }
}
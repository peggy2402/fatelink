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
}
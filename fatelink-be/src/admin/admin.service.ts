import { Injectable, UnauthorizedException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { SystemConfig, SystemConfigDocument } from './schemas/system-config.schema';

@Injectable()
export class AdminService {
  constructor(
    @InjectModel(SystemConfig.name) private configModel: Model<SystemConfigDocument>,
    @InjectModel('User') private userModel: Model<any>, // Đảm bảo AdminModule đã import MongooseModule.forFeature([{ name: 'User', schema: UserSchema }])
  ) {}

  // Lấy cấu hình hiện tại (nếu chưa có thì tạo mặc định 1 bản ghi duy nhất)
  async getConfig(): Promise<SystemConfigDocument> {
    let config = await this.configModel.findOne().exec();
    if (!config) {
      config = await this.configModel.create({});
    }
    return config;
  }

  // Cập nhật cấu hình
  async updateConfig(updateData: Partial<SystemConfig>): Promise<SystemConfigDocument | null> {
    const config = await this.getConfig();
    return this.configModel.findByIdAndUpdate(config._id, updateData, { new: true }).exec();
  }

  // Đăng nhập Admin (Hardcode bảo mật qua Biến môi trường)
  login(username: string, pass: string) {
    const envUsername = process.env.ADMIN_USERNAME;
    const envPassword = process.env.ADMIN_PASSWORD; // Đổi mật khẩu này trong file .env

    if (username === envUsername && pass === envPassword) {
      // Ở mức production, bạn nên dùng JwtService để sinh ra token JWT chuẩn, ở đây làm ví dụ nhanh:
      return { accessToken: 'admin-super-secret-token', role: 'admin' };
    }
    throw new UnauthorizedException('Sai tài khoản hoặc mật khẩu quản trị viên!');
  }

  // Lấy danh sách người dùng
  async getUsers() {
    return this.userModel.find().select('-password').sort({ createdAt: -1 }).exec();
  }

  // Khóa / Mở khóa tài khoản
  async banUser(userId: string, isBanned: boolean) {
    return this.userModel.findByIdAndUpdate(userId, { isBanned }, { new: true }).exec();
  }
}
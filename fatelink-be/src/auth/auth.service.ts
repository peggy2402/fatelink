import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OAuth2Client } from 'google-auth-library';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import { CreateUserDto } from '../users/dto/create-user.dto';

@Injectable()
export class AuthService {
  private googleClient: OAuth2Client;

  constructor(
    private configService: ConfigService,
    private usersService: UsersService,
    private jwtService: JwtService,
  ) {
    const clientId = this.configService.get<string>('GOOGLE_CLIENT_ID');
    // Khởi tạo Google Client với Client ID từ file .env
    this.googleClient = new OAuth2Client(clientId);
  }

  async verifyGoogleToken(token: string) {
    try {
      // 1. Xác thực token với Google
      const ticket = await this.googleClient.verifyIdToken({
        idToken: token,
        audience: this.configService.get<string>('GOOGLE_CLIENT_ID'),
      });

      // 2. Lấy thông tin user từ token hợp lệ
      const payload = ticket.getPayload();
      
      if (!payload || !payload.email) {
        throw new UnauthorizedException('Không thể lấy thông tin từ Google Token hoặc thiếu Email');
      }

      console.log('Thông tin user từ Google:', payload);

      // 3. Tìm hoặc tạo User mới trong MongoDB
      const userProfile: CreateUserDto = {
        email: payload.email,
        name: payload.name || '',
        avatar: payload.picture || '',
        googleId: payload.sub,
      };
      
      const user = await this.usersService.findOrCreate(userProfile);

      // 4. Tạo JWT Token cho user
      // Thêm tokenVersion vào Payload để bảo mật Token Versioning
      const jwtPayload = { 
        sub: user._id, 
        email: user.email, 
        tokenVersion: user.tokenVersion || 0 
      };
      const accessToken = this.jwtService.sign(jwtPayload);

      return {
        user,
        accessToken,
      };
      
    } catch (error) {
      console.error('Lỗi xác thực Google Token:', error);
      throw new UnauthorizedException('Token không hợp lệ hoặc đã hết hạn');
    }
  }

  // Hàm Đăng xuất: Tăng tokenVersion để vô hiệu hoá toàn bộ token cũ
  async logout(userId: string) {
    // Giả định usersService có hàm incrementTokenVersion hoặc update
    await this.usersService.incrementTokenVersion(userId);
    return { message: 'Đăng xuất thành công, token đã bị thu hồi.' };
  }
}

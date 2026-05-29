import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { OAuth2Client } from 'google-auth-library';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { UsersService } from '../users/users.service';
import { AUTH_ENV } from './shared/auth.constants';

@Injectable()
export class AuthService {
  private googleClient: OAuth2Client;

  constructor(
    private readonly configService: ConfigService,
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
  ) {
    const clientId = this.configService.get<string>(AUTH_ENV.GOOGLE_CLIENT_ID);
    this.googleClient = new OAuth2Client(clientId);
  }

  async verifyGoogleToken(token: string) {
    try {
      const ticket = await this.googleClient.verifyIdToken({
        idToken: token,
        audience: this.configService.get<string>(AUTH_ENV.GOOGLE_CLIENT_ID),
      });

      const payload = ticket.getPayload();

      if (!payload || !payload.email) {
        throw new UnauthorizedException(
          'Không thể lấy thông tin từ Google Token hoặc thiếu Email',
        );
      }

      const userProfile: CreateUserDto = {
        email: payload.email,
        name: payload.name || '',
        avatar: payload.picture || '',
        googleId: payload.sub,
      };

      const user = await this.usersService.findOrCreate(userProfile);

      const jwtPayload = {
        sub: user._id,
        email: user.email,
        tokenVersion: user.tokenVersion || 0,
      };
      const accessToken = this.jwtService.sign(jwtPayload);

      return {
        user,
        accessToken,
      };
    } catch {
      throw new UnauthorizedException('Token không hợp lệ hoặc đã hết hạn.');
    }
  }

  async logout(userId: string) {
    await this.usersService.incrementTokenVersion(userId);
    return { message: 'Đăng xuất thành công, token đã bị thu hồi.' };
  }
}

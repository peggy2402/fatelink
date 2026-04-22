import { Body, Controller, Post } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}
  @Post('google/login')
  async handleGoogleLogin(@Body('token') token: string) {
    // Gọi hàm xác thực từ Service
    const result = await this.authService.verifyGoogleToken(token);
    return {
      success: true,
      message: 'Xác thực Google thành công!',
      data: result.user,
      accessToken: result.accessToken,
    };
  }
}

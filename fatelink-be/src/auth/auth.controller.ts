import { Body, Controller, Post, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBody, ApiBearerAuth } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './jwt-auth.guard';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('google/login')
  @ApiOperation({ summary: 'Đăng nhập bằng Google Token từ Flutter' })
  @ApiBody({ schema: { type: 'object', properties: { token: { type: 'string', description: 'ID Token từ Google OAuth', example: 'eyJhbGciOiJSUzI1...' } } } })
  @ApiResponse({ status: 200, description: 'Đăng nhập thành công, trả về thông tin User và Access Token.' })
  @ApiResponse({ status: 401, description: 'Token không hợp lệ hoặc hết hạn.' })
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

  @Post('logout')
  @UseGuards(JwtAuthGuard) // Bắt buộc phải có token hợp lệ mới được đăng xuất
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Đăng xuất người dùng (Vô hiệu hoá token hiện tại)' })
  @ApiResponse({ status: 200, description: 'Đăng xuất thành công, token đã bị thu hồi.' })
  async logout(@Request() req) {
    return this.authService.logout(req.user.sub);
  }
}

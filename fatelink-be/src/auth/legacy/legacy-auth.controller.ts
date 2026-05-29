import {
  Body,
  Controller,
  Post,
  Request as NestRequest,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { Request } from 'express';
import { AuthJwtPayload } from '../auth-jwt-payload.interface';
import { LegacyAuthService } from './legacy-auth.service';
import { LegacyJwtAuthGuard } from './legacy-jwt-auth.guard';

type AuthenticatedRequest = Request & {
  user: AuthJwtPayload;
};

@ApiTags('Auth')
@Controller('auth')
export class LegacyAuthController {
  constructor(private readonly legacyAuthService: LegacyAuthService) {}

  @Post('google/login')
  @ApiOperation({ summary: 'Đăng nhập bằng Google Token từ Flutter' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        token: {
          type: 'string',
          description: 'ID Token từ Google OAuth',
          example: 'eyJhbGciOiJSUzI1...',
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Đăng nhập thành công, trả về thông tin User và Access Token.',
  })
  @ApiResponse({
    status: 401,
    description: 'Token không hợp lệ hoặc đã hết hạn.',
  })
  async handleGoogleLogin(@Body('token') token: string) {
    const result = await this.legacyAuthService.verifyGoogleToken(token);
    return {
      success: true,
      message: 'Xác thực Google thành công!',
      data: result.user,
      accessToken: result.accessToken,
    };
  }

  @Post('logout')
  @UseGuards(LegacyJwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Đăng xuất người dùng (Vô hiệu hoá token hiện tại)',
  })
  @ApiResponse({
    status: 200,
    description: 'Đăng xuất thành công, token đã bị thu hồi.',
  })
  async logout(@NestRequest() req: AuthenticatedRequest) {
    return this.legacyAuthService.logout(req.user.sub);
  }
}

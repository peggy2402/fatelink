import {
  Body,
  Controller,
  Post,
  Request as NestRequest,
  UseGuards,
} from '@nestjs/common';
import { Request } from 'express';
import { JwtAuthGuard } from '../../jwt-auth.guard';
import { RefreshTokenDto } from '../dto/refresh-token.dto';
import { SecurityService } from './security.service';
import {
  ApiV2Logout,
  ApiV2Refresh,
  ApiV2SecurityController,
} from './security.swagger';

type AuthenticatedRequest = Request & {
  user: {
    sub: string;
  };
};

@ApiV2SecurityController()
@Controller('auth/v2/security')
export class SecurityController {
  constructor(private readonly securityService: SecurityService) {}

  @Post('logout')
  @UseGuards(JwtAuthGuard)
  @ApiV2Logout()
  async logout(@NestRequest() req: AuthenticatedRequest) {
    return this.securityService.logout(req.user.sub);
  }

  @Post('refresh')
  @ApiV2Refresh()
  async refresh(@Body() body: RefreshTokenDto) {
    const result = await this.securityService.refresh(body.refreshToken);

    return {
      success: true,
      message: 'Cấp mới token thành công.',
      data: result.user,
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    };
  }
}

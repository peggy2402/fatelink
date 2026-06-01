import {
  Body,
  Controller,
  Inject,
  Post,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import type { GoogleLoginUseCase } from '@contexts/auth/application/usecases/google-login.usecase';
import type { LogoutUseCase } from '@contexts/auth/application/usecases/logout.usecase';
import { AUTH_APPLICATION_TOKENS } from '@contexts/auth/composition/auth.tokens';
import { JwtAuthGuard } from '@contexts/auth/presentation/http/guards/jwt-auth.guard';
import {
  ApiGoogleLogin,
  ApiLogout,
} from '@contexts/auth/presentation/http/docs/auth.swagger';
import type { AuthenticatedRequest } from '@shared/presentation/types/authenticated-request';
import { GoogleLoginDto } from '../dtos/auth.request.dto';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(
    @Inject(AUTH_APPLICATION_TOKENS.googleLogin)
    private readonly googleLoginUseCase: GoogleLoginUseCase,
    @Inject(AUTH_APPLICATION_TOKENS.logout)
    private readonly logoutUseCase: LogoutUseCase,
  ) {}

  @Post('google/login')
  @ApiGoogleLogin()
  async handleGoogleLogin(@Body() dto: GoogleLoginDto) {
    const result = await this.googleLoginUseCase.execute({ token: dto.token });
    return {
      success: true,
      message: 'Xác thực Google thành công!',
      data: result.user,
      accessToken: result.accessToken,
    };
  }

  @Post('logout')
  @UseGuards(JwtAuthGuard) // Bắt buộc phải có token hợp lệ mới được đăng xuất
  @ApiLogout()
  async logout(@Request() req: AuthenticatedRequest) {
    return this.logoutUseCase.execute({ userId: req.user.sub });
  }
}

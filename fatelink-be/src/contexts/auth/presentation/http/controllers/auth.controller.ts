import {
  Body,
  Controller,
  Get,
  Inject,
  Param,
  Post,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import type { LoginWithEmailUseCase } from '@contexts/auth/application/usecases/login-with-email.usecase';
import type { LoginWithFacebookUseCase } from '@contexts/auth/application/usecases/login-with-facebook.usecase';
import type { LoginWithGoogleUseCase } from '@contexts/auth/application/usecases/login-with-google.usecase';
import type { LoginWithMagicLinkUseCase } from '@contexts/auth/application/usecases/login-with-magic-link.usecase';
import type { LoginWithPhoneOtpUseCase } from '@contexts/auth/application/usecases/login-with-phone-otp.usecase';
import type { ListAuthSessionsUseCase } from '@contexts/auth/application/usecases/list-auth-sessions.usecase';
import type { LogoutUseCase } from '@contexts/auth/application/usecases/logout.usecase';
import type { RefreshTokenUseCase } from '@contexts/auth/application/usecases/refresh-token.usecase';
import type { RevokeAuthSessionUseCase } from '@contexts/auth/application/usecases/revoke-auth-session.usecase';
import type { RegisterWithEmailUseCase } from '@contexts/auth/application/usecases/register-with-email.usecase';
import type { RequestMagicLinkUseCase } from '@contexts/auth/application/usecases/request-magic-link.usecase';
import type { RequestPhoneOtpUseCase } from '@contexts/auth/application/usecases/request-phone-otp.usecase';
import { AUTH_APPLICATION_TOKENS } from '@contexts/auth/composition/auth.tokens';
import { JwtAuthGuard } from '@contexts/auth/presentation/http/guards/jwt-auth.guard';
import {
  ApiLoginWithEmail,
  ApiLoginWithFacebook,
  ApiLoginWithGoogle,
  ApiLoginWithMagicLink,
  ApiLoginWithPhoneOtp,
  ApiListAuthSessions,
  ApiLogout,
  ApiRefreshToken,
  ApiRevokeAuthSession,
  ApiRegisterWithEmail,
  ApiRequestMagicLink,
  ApiRequestPhoneOtp,
} from '@contexts/auth/presentation/http/docs/auth.swagger';
import type { AuthenticatedRequest } from '@shared/presentation/types/authenticated-request';
import type { Request as HttpRequest } from 'express';
import {
  LoginWithEmailDto,
  LoginWithFacebookDto,
  LoginWithGoogleDto,
  LoginWithMagicLinkDto,
  LoginWithPhoneOtpDto,
  RefreshTokenDto,
  RegisterWithEmailDto,
  RequestMagicLinkDto,
  RequestPhoneOtpDto,
} from '../dtos/auth.request.dto';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(
    @Inject(AUTH_APPLICATION_TOKENS.loginWithGoogle)
    private readonly loginWithGoogleUseCase: LoginWithGoogleUseCase,
    @Inject(AUTH_APPLICATION_TOKENS.registerWithEmail)
    private readonly registerWithEmailUseCase: RegisterWithEmailUseCase,
    @Inject(AUTH_APPLICATION_TOKENS.loginWithEmail)
    private readonly loginWithEmailUseCase: LoginWithEmailUseCase,
    @Inject(AUTH_APPLICATION_TOKENS.requestPhoneOtp)
    private readonly requestPhoneOtpUseCase: RequestPhoneOtpUseCase,
    @Inject(AUTH_APPLICATION_TOKENS.loginWithPhoneOtp)
    private readonly loginWithPhoneOtpUseCase: LoginWithPhoneOtpUseCase,
    @Inject(AUTH_APPLICATION_TOKENS.requestMagicLink)
    private readonly requestMagicLinkUseCase: RequestMagicLinkUseCase,
    @Inject(AUTH_APPLICATION_TOKENS.loginWithMagicLink)
    private readonly loginWithMagicLinkUseCase: LoginWithMagicLinkUseCase,
    @Inject(AUTH_APPLICATION_TOKENS.loginWithFacebook)
    private readonly loginWithFacebookUseCase: LoginWithFacebookUseCase,
    @Inject(AUTH_APPLICATION_TOKENS.listAuthSessions)
    private readonly listAuthSessionsUseCase: ListAuthSessionsUseCase,
    @Inject(AUTH_APPLICATION_TOKENS.revokeAuthSession)
    private readonly revokeAuthSessionUseCase: RevokeAuthSessionUseCase,
    @Inject(AUTH_APPLICATION_TOKENS.logout)
    private readonly logoutUseCase: LogoutUseCase,
    @Inject(AUTH_APPLICATION_TOKENS.refreshToken)
    private readonly refreshTokenUseCase: RefreshTokenUseCase,
  ) {}

  @Post('google/login')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @ApiLoginWithGoogle()
  async loginWithGoogle(
    @Body() dto: LoginWithGoogleDto,
    @Request() req: HttpRequest,
  ) {
    return this.toAuthResponse(
      await this.loginWithGoogleUseCase.execute({
        token: dto.token,
        deviceType: dto.deviceType,
        deviceId: dto.deviceId,
        context: this.getSessionContext(req, dto.deviceId),
      }),
      'Xác thực Google thành công!',
    );
  }

  @Post('email/register')
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @ApiRegisterWithEmail()
  async registerWithEmail(
    @Body() dto: RegisterWithEmailDto,
    @Request() req: HttpRequest,
  ) {
    return this.toAuthResponse(
      await this.registerWithEmailUseCase.execute({
        ...dto,
        context: this.getSessionContext(req, dto.deviceId),
      }),
      'Đăng ký email thành công!',
    );
  }

  @Post('email/login')
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @ApiLoginWithEmail()
  async loginWithEmail(
    @Body() dto: LoginWithEmailDto,
    @Request() req: HttpRequest,
  ) {
    return this.toAuthResponse(
      await this.loginWithEmailUseCase.execute({
        ...dto,
        context: this.getSessionContext(req, dto.deviceId),
      }),
      'Đăng nhập email thành công!',
    );
  }

  @Post('phone/request-otp')
  @Throttle({ default: { limit: 3, ttl: 60000 } })
  @ApiRequestPhoneOtp()
  requestPhoneOtp(@Body() dto: RequestPhoneOtpDto) {
    return this.toRequestChallengeResponse(
      this.requestPhoneOtpUseCase.execute(dto),
      'Yêu cầu OTP thành công.',
    );
  }

  @Post('phone/login')
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @ApiLoginWithPhoneOtp()
  async loginWithPhoneOtp(
    @Body() dto: LoginWithPhoneOtpDto,
    @Request() req: HttpRequest,
  ) {
    return this.toAuthResponse(
      await this.loginWithPhoneOtpUseCase.execute({
        ...dto,
        context: this.getSessionContext(req, dto.deviceId),
      }),
      'Đăng nhập số điện thoại thành công!',
    );
  }

  @Post('magic-link/request')
  @Throttle({ default: { limit: 3, ttl: 60000 } })
  @ApiRequestMagicLink()
  requestMagicLink(@Body() dto: RequestMagicLinkDto) {
    return this.toRequestChallengeResponse(
      this.requestMagicLinkUseCase.execute(dto),
      'Yêu cầu magic link thành công.',
    );
  }

  @Post('magic-link/login')
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @ApiLoginWithMagicLink()
  async loginWithMagicLink(
    @Body() dto: LoginWithMagicLinkDto,
    @Request() req: HttpRequest,
  ) {
    return this.toAuthResponse(
      await this.loginWithMagicLinkUseCase.execute({
        ...dto,
        context: this.getSessionContext(req, dto.deviceId),
      }),
      'Đăng nhập magic link thành công!',
    );
  }

  @Post('facebook/login')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @ApiLoginWithFacebook()
  async loginWithFacebook(
    @Body() dto: LoginWithFacebookDto,
    @Request() req: HttpRequest,
  ) {
    return this.toAuthResponse(
      await this.loginWithFacebookUseCase.execute({
        ...dto,
        context: this.getSessionContext(req, dto.deviceId),
      }),
      'Đăng nhập Facebook thành công!',
    );
  }

  @Post('refresh')
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @ApiRefreshToken()
  async refresh(@Body() dto: RefreshTokenDto, @Request() req: HttpRequest) {
    return this.toAuthResponse(
      await this.refreshTokenUseCase.execute({
        refreshToken: dto.refreshToken,
        context: this.getSessionContext(req, dto.deviceId),
      }),
      'Cấp mới token thành công.',
    );
  }

  @Get('sessions')
  @UseGuards(JwtAuthGuard)
  @ApiListAuthSessions()
  async listSessions(@Request() req: AuthenticatedRequest) {
    return {
      success: true,
      message: 'Lấy danh sách session thành công.',
      data: await this.listAuthSessionsUseCase.execute({
        userId: req.user.sub,
        currentSessionId: req.user.sessionId,
      }),
    };
  }

  @Post('sessions/:sessionId/revoke')
  @UseGuards(JwtAuthGuard)
  @ApiRevokeAuthSession()
  async revokeSession(
    @Param('sessionId') sessionId: string,
    @Request() req: AuthenticatedRequest,
  ) {
    const result = await this.revokeAuthSessionUseCase.execute({
      userId: req.user.sub,
      sessionId,
    });
    return this.toMessageResponse(result.message);
  }

  @Post('logout')
  @UseGuards(JwtAuthGuard) // Bắt buộc phải có token hợp lệ mới được đăng xuất
  @ApiLogout()
  async logout(@Request() req: AuthenticatedRequest) {
    const result = await this.logoutUseCase.execute({
      sessionId: req.user.sessionId || '',
    });
    return this.toMessageResponse(result.message);
  }

  private toAuthResponse(
    result: {
      user: {
        id?: string;
        email?: string;
        name?: string;
        avatar?: string;
        latestEmotion?: string;
        emotions?: {
          stress: number;
          loneliness: number;
          sadness: number;
          calmness: number;
          warmth: number;
          happiness: number;
        };
        personality?: number[];
        bio?: string;
        fcmToken?: string;
      };
      accessToken: string;
      refreshToken: string;
    },
    message: string,
  ) {
    const user = {
      ...result.user,
      _id: result.user.id,
    };

    return {
      success: true,
      message,
      data: user,
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    };
  }

  private async toRequestChallengeResponse<T extends { message: string }>(
    promise: Promise<T>,
    message: string,
  ) {
    const result = await promise;
    const { message: _ignored, ...data } = result;
    return {
      success: true,
      message,
      data,
    };
  }

  private toMessageResponse(message: string) {
    return {
      success: true,
      message,
    };
  }

  private getSessionContext(req: HttpRequest, deviceId?: string) {
    const forwardedFor = req.headers['x-forwarded-for'];
    const ipAddress = Array.isArray(forwardedFor)
      ? forwardedFor[0]
      : forwardedFor?.split(',')[0]?.trim() || req.ip;
    const userAgentHeader = req.get('user-agent');
    const userAgent =
      typeof userAgentHeader === 'string' ? userAgentHeader : undefined;

    return {
      deviceId,
      ipAddress,
      userAgent,
    };
  }
}

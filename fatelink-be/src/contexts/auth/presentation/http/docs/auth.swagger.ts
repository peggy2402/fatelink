import { applyDecorators } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiOkResponse,
  ApiOperation,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import {
  AuthTokensResponseDto,
  ListAuthSessionsResponseDto,
  RequestMagicLinkResponseDto,
  RequestPhoneOtpResponseDto,
  SimpleMessageResponseDto,
} from '../dtos/auth.response.dto';

export function ApiLoginWithGoogle() {
  return applyDecorators(
    ApiOperation({ summary: 'Đăng nhập bằng Google ID token' }),
    ApiBody({
      schema: {
        type: 'object',
        required: ['token', 'deviceId'],
        properties: {
          token: {
            type: 'string',
            description: 'ID token từ Google OAuth',
            example: 'eyJhbGciOiJSUzI1NiIsImtpZCI6I...',
          },
          deviceType: {
            type: 'string',
            enum: ['web', 'desktop', 'mobile'],
            description: 'Loại thiết bị đang đăng nhập',
            example: 'mobile',
          },
          deviceId: {
            type: 'string',
            description: 'Định danh ổn định của thiết bị',
            example: 'iphone-15-pro-max-user-123',
          },
        },
      },
    }),
    ApiOkResponse({
      description: 'Đăng nhập thành công, trả về user và cặp token.',
      type: AuthTokensResponseDto,
    }),
    ApiUnauthorizedResponse({
      description: 'Google token không hợp lệ hoặc đã hết hạn.',
    }),
  );
}

export function ApiRefreshToken() {
  return applyDecorators(
    ApiOperation({ summary: 'Cấp mới access token và refresh token' }),
    ApiBody({
      schema: {
        type: 'object',
        required: ['refreshToken', 'deviceId'],
        properties: {
          refreshToken: {
            type: 'string',
            example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.refresh-token',
          },
          deviceId: {
            type: 'string',
            example: 'iphone-15-pro-max-user-123',
          },
        },
      },
    }),
    ApiOkResponse({
      description: 'Cấp mới token thành công.',
      type: AuthTokensResponseDto,
    }),
    ApiUnauthorizedResponse({
      description: 'Refresh token không hợp lệ, sai thiết bị hoặc đã bị thu hồi.',
    }),
  );
}

export function ApiLogout() {
  return applyDecorators(
    ApiBearerAuth(),
    ApiOperation({
      summary: 'Đăng xuất người dùng và thu hồi phiên hiện tại',
    }),
    ApiOkResponse({
      description: 'Đăng xuất thành công.',
      type: SimpleMessageResponseDto,
    }),
  );
}

export function ApiListAuthSessions() {
  return applyDecorators(
    ApiBearerAuth(),
    ApiOperation({
      summary: 'Lấy danh sách phiên đăng nhập của người dùng',
    }),
    ApiOkResponse({
      description: 'Lấy danh sách session thành công.',
      type: ListAuthSessionsResponseDto,
    }),
  );
}

export function ApiRevokeAuthSession() {
  return applyDecorators(
    ApiBearerAuth(),
    ApiOperation({
      summary: 'Thu hồi một phiên đăng nhập cụ thể của người dùng hiện tại',
    }),
    ApiOkResponse({
      description: 'Thu hồi session thành công.',
      type: SimpleMessageResponseDto,
    }),
  );
}

export function ApiRegisterWithEmail() {
  return applyDecorators(
    ApiOperation({ summary: 'Đăng ký bằng email và mật khẩu' }),
    ApiOkResponse({
      description: 'Đăng ký thành công, trả về user và cặp token.',
      type: AuthTokensResponseDto,
    }),
  );
}

export function ApiLoginWithEmail() {
  return applyDecorators(
    ApiOperation({ summary: 'Đăng nhập bằng email và mật khẩu' }),
    ApiOkResponse({
      description: 'Đăng nhập thành công, trả về user và cặp token.',
      type: AuthTokensResponseDto,
    }),
  );
}

export function ApiRequestPhoneOtp() {
  return applyDecorators(
    ApiOperation({ summary: 'Yêu cầu OTP đăng nhập số điện thoại' }),
    ApiOkResponse({
      description: 'OTP được tạo thành công.',
      type: RequestPhoneOtpResponseDto,
    }),
  );
}

export function ApiLoginWithPhoneOtp() {
  return applyDecorators(
    ApiOperation({ summary: 'Đăng nhập bằng số điện thoại và OTP' }),
    ApiOkResponse({
      description: 'Đăng nhập thành công, trả về user và cặp token.',
      type: AuthTokensResponseDto,
    }),
  );
}

export function ApiRequestMagicLink() {
  return applyDecorators(
    ApiOperation({ summary: 'Yêu cầu magic link đăng nhập' }),
    ApiOkResponse({
      description: 'Magic link được tạo thành công.',
      type: RequestMagicLinkResponseDto,
    }),
  );
}

export function ApiLoginWithMagicLink() {
  return applyDecorators(
    ApiOperation({ summary: 'Đăng nhập bằng magic link dùng một lần' }),
    ApiOkResponse({
      description: 'Đăng nhập thành công, trả về user và cặp token.',
      type: AuthTokensResponseDto,
    }),
  );
}

export function ApiLoginWithFacebook() {
  return applyDecorators(
    ApiOperation({ summary: 'Đăng nhập bằng Facebook access token' }),
    ApiOkResponse({
      description: 'Đăng nhập thành công, trả về user và cặp token.',
      type: AuthTokensResponseDto,
    }),
  );
}

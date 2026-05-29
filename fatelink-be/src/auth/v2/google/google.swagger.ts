import { applyDecorators } from '@nestjs/common';
import {
  ApiBody,
  ApiOkResponse,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { AuthTokenPairResponseDto } from '../dto/auth-token-pair-response.dto';
import { GoogleAuthTokenDto } from '../dto/google-auth-token.dto';

export function ApiV2GoogleController() {
  return applyDecorators(ApiTags('Auth V2 Google'));
}

export function ApiV2GoogleAuthenticate() {
  return applyDecorators(
    ApiOperation({
      summary: 'Đăng nhập với Google và tự động tạo tài khoản nếu chưa tồn tại',
    }),
    ApiBody({ type: GoogleAuthTokenDto }),
    ApiOkResponse({
      description:
        'Xác thực Google thành công, tự động tạo tài khoản nếu chưa có và trả về access token cùng refresh token.',
      type: AuthTokenPairResponseDto,
    }),
    ApiResponse({
      status: 401,
      description: 'Google token không hợp lệ.',
    }),
  );
}

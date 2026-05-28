import { applyDecorators } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiOkResponse,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { AuthTokenPairResponseDto } from '../dto/auth-token-pair-response.dto';
import { RefreshTokenDto } from '../dto/refresh-token.dto';

export function ApiV2SecurityController() {
  return applyDecorators(ApiTags('Auth V2 Security'));
}

export function ApiV2Logout() {
  return applyDecorators(
    ApiBearerAuth(),
    ApiOperation({ summary: 'Đăng xuất và thu hồi toàn bộ token hiện có' }),
    ApiResponse({
      status: 200,
      description: 'Đăng xuất thành công, token đã bị thu hồi.',
    }),
  );
}

export function ApiV2Refresh() {
  return applyDecorators(
    ApiOperation({
      summary:
        'Cấp mới access token và refresh token theo cơ chế rotate một lần',
    }),
    ApiBody({ type: RefreshTokenDto }),
    ApiOkResponse({
      description:
        'Cấp mới access token và refresh token thành công theo cơ chế một lần.',
      type: AuthTokenPairResponseDto,
    }),
    ApiResponse({
      status: 401,
      description:
        'Refresh token không hợp lệ, đã hết hạn hoặc đã được sử dụng.',
    }),
  );
}

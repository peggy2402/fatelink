import { HttpStatus } from '@nestjs/common';
import { APP_ERROR_CODES, AppErrorCode } from './app-error-codes';

type AppErrorDefinition = {
  message: string;
  status: HttpStatus;
};

export const APP_ERROR_MAP: Record<AppErrorCode, AppErrorDefinition> = {
  [APP_ERROR_CODES.AUTH_GOOGLE_EMAIL_MISSING]: {
    status: HttpStatus.UNAUTHORIZED,
    message: 'Không thể lấy thông tin email từ Google token.',
  },
  [APP_ERROR_CODES.AUTH_SESSION_INIT_FAILED]: {
    status: HttpStatus.UNAUTHORIZED,
    message: 'Không thể khởi tạo phiên đăng nhập mới.',
  },
  [APP_ERROR_CODES.AUTH_REFRESH_TOKEN_INVALID_TYPE]: {
    status: HttpStatus.UNAUTHORIZED,
    message: 'Refresh token không đúng loại.',
  },
  [APP_ERROR_CODES.AUTH_REFRESH_USER_NOT_FOUND]: {
    status: HttpStatus.UNAUTHORIZED,
    message: 'Không tìm thấy tài khoản tương ứng với refresh token.',
  },
  [APP_ERROR_CODES.AUTH_REFRESH_TOKEN_REVOKED]: {
    status: HttpStatus.UNAUTHORIZED,
    message: 'Refresh token không còn hợp lệ hoặc đã được sử dụng.',
  },
  [APP_ERROR_CODES.AUTH_REFRESH_TOKEN_INVALID_OR_EXPIRED]: {
    status: HttpStatus.UNAUTHORIZED,
    message: 'Refresh token không hợp lệ hoặc đã hết hạn.',
  },
};

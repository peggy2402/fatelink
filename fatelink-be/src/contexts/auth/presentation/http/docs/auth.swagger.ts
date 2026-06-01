import { applyDecorators } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiOperation,
  ApiResponse,
} from '@nestjs/swagger';

export function ApiGoogleLogin() {
  return applyDecorators(
    ApiOperation({ summary: 'Dang nhap bang Google Token tu Flutter' }),
    ApiBody({
      schema: {
        type: 'object',
        properties: {
          token: {
            type: 'string',
            description: 'ID Token tu Google OAuth',
            example: 'eyJhbGciOiJSUzI1...',
          },
        },
      },
    }),
    ApiResponse({
      status: 200,
      description:
        'Dang nhap thanh cong, tra ve thong tin User va Access Token.',
    }),
    ApiResponse({
      status: 401,
      description: 'Token khong hop le hoac het han.',
    }),
  );
}

export function ApiLogout() {
  return applyDecorators(
    ApiBearerAuth(),
    ApiOperation({
      summary: 'Dang xuat nguoi dung (Vo hieu hoa token hien tai)',
    }),
    ApiResponse({
      status: 200,
      description: 'Dang xuat thanh cong, token da bi thu hoi.',
    }),
  );
}

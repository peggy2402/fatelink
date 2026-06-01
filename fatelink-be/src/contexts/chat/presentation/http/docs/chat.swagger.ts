import { applyDecorators } from '@nestjs/common';
import { ApiBody, ApiOperation, ApiResponse } from '@nestjs/swagger';

export function ApiSendAiMessage() {
  return applyDecorators(
    ApiOperation({ summary: 'Gui tin nhan cho AI (Faye) va nhan phan hoi' }),
    ApiBody({
      schema: {
        type: 'object',
        properties: {
          message: {
            type: 'string',
            example: 'Hom nay minh hoi met moi chut...',
          },
          history: {
            type: 'array',
            items: { type: 'object' },
            description: 'Mang lich su chat truyen tu client',
          },
        },
      },
    }),
    ApiResponse({ status: 201, description: 'AI tra loi thanh cong.' }),
  );
}

import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';

@ApiTags('Default')
@Controller()
export class AppController {
  @Get()
  @ApiOperation({ summary: 'Kiểm tra trạng thái Server (Ping)' })
  @ApiResponse({
    status: 200,
    description: 'Trả về câu chào để xác nhận Server đang hoạt động.',
  })
  getHello(): string {
    return 'Fatelink API is running';
  }
}

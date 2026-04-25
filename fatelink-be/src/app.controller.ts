import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { AppService } from './app.service';

@ApiTags('Default')
@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  @ApiOperation({ summary: 'Kiểm tra trạng thái Server (Ping)' })
  @ApiResponse({ status: 200, description: 'Trả về câu chào để xác nhận Server đang hoạt động.' })
  getHello(): string {
    return this.appService.getHello();
  }
}

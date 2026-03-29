import { Controller, Post, Body } from '@nestjs/common';
import { SupportService } from './support.service';
import { CreateSupportDto } from './dto/create-support.dto';
import { Throttle } from '@nestjs/throttler';

@Controller('api/support')
export class SupportController {
  constructor(private readonly supportService: SupportService) {}

  @Post()
  @Throttle({ default: { limit: 3, ttl: 60000 } }) // Chỉ cho phép 3 request mỗi 60 giây
  async submitSupport(@Body() createSupportDto: CreateSupportDto) {
    return this.supportService.submitSupport(createSupportDto);
  }
}

import { Controller, Post, Body } from '@nestjs/common';
import { SupportService } from './support.service';
import { CreateSupportDto } from './dto/create-support.dto';

@Controller('support')
export class SupportController {
  constructor(private readonly supportService: SupportService) {}

  @Post()
  async submitSupport(@Body() createSupportDto: CreateSupportDto) {
    return this.supportService.submitSupport(createSupportDto);
  }
}

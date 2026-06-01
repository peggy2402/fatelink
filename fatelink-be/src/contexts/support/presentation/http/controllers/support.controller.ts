import { Controller, Inject, Post, Body } from '@nestjs/common';
import type { SubmitSupportUseCase } from '@contexts/support/application/usecases/submit-support.usecase';
import { SUPPORT_APPLICATION_TOKENS } from '@contexts/support/composition/support.tokens';
import { CreateSupportDto } from '../dtos/support.request.dto';
import { Throttle } from '@nestjs/throttler';

@Controller('support')
export class SupportController {
  constructor(
    @Inject(SUPPORT_APPLICATION_TOKENS.submitSupport)
    private readonly submitSupportUseCase: SubmitSupportUseCase,
  ) {}

  @Post()
  @Throttle({ default: { limit: 3, ttl: 60000 } }) // Chỉ cho phép 3 request mỗi 60 giây
  async submitSupport(@Body() createSupportDto: CreateSupportDto) {
    return this.submitSupportUseCase.execute(createSupportDto);
  }
}

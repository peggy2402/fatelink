import { Module } from '@nestjs/common';
import { SupportController } from '@contexts/support/presentation/http/controllers/support.controller';
import { SupportApplicationModule } from './support-application.module';

@Module({
  imports: [SupportApplicationModule],
  controllers: [SupportController],
})
export class SupportContextModule {}

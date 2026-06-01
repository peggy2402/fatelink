import { supportUseCaseProviders, supportUseCases } from './support.providers';
import { SupportInfrastructureModule } from '@contexts/support/infrastructure/support-infrastructure.module';
import { Module } from '@nestjs/common';

@Module({
  imports: [SupportInfrastructureModule],
  providers: supportUseCaseProviders,
  exports: supportUseCases,
})
export class SupportApplicationModule {}

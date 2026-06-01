import { aiUseCaseProviders, aiUseCases } from './ai.providers';
import { AdminPersistenceModule } from '@contexts/admin/infrastructure/admin-persistence.module';
import { Module } from '@nestjs/common';
import { SharedAiProvidersModule } from '@shared/infrastructure/ai-providers.module';

@Module({
  imports: [SharedAiProvidersModule, AdminPersistenceModule],
  providers: aiUseCaseProviders,
  exports: aiUseCases,
})
export class AiApplicationModule {}

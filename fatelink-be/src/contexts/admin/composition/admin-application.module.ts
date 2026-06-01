import { adminUseCaseProviders, adminUseCases } from './admin.providers';
import { AdminPersistenceModule } from '@contexts/admin/infrastructure/admin-persistence.module';
import { AuthInfrastructureModule } from '@contexts/auth/infrastructure/auth-infrastructure.module';
import { SupportInfrastructureModule } from '@contexts/support/infrastructure/support-infrastructure.module';
import { UsersPersistenceModule } from '@contexts/users/infrastructure/users-persistence.module';
import { Module } from '@nestjs/common';
import { SharedAiProvidersModule } from '@shared/infrastructure/ai-providers.module';

@Module({
  imports: [
    AdminPersistenceModule,
    AuthInfrastructureModule,
    SupportInfrastructureModule,
    UsersPersistenceModule,
    SharedAiProvidersModule,
  ],
  providers: adminUseCaseProviders,
  exports: adminUseCases,
})
export class AdminApplicationModule {}

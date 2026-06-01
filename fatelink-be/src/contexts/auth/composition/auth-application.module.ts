import { authUseCaseProviders, authUseCases } from './auth.providers';
import { AuthInfrastructureModule } from '@contexts/auth/infrastructure/auth-infrastructure.module';
import { UsersPersistenceModule } from '@contexts/users/infrastructure/users-persistence.module';
import { Module } from '@nestjs/common';

@Module({
  imports: [AuthInfrastructureModule, UsersPersistenceModule],
  providers: authUseCaseProviders,
  exports: authUseCases,
})
export class AuthApplicationModule {}

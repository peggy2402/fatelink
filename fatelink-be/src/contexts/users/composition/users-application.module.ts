import { usersUseCaseProviders, usersUseCases } from './users.providers';
import { UsersPersistenceModule } from '@contexts/users/infrastructure/users-persistence.module';
import { Module } from '@nestjs/common';

@Module({
  imports: [UsersPersistenceModule],
  providers: usersUseCaseProviders,
  exports: usersUseCases,
})
export class UsersApplicationModule {}

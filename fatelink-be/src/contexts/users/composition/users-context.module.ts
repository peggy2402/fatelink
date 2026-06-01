import { Module } from '@nestjs/common';
import { AuthSecurityModule } from '@contexts/auth/composition/auth-security.module';
import { UsersController } from '@contexts/users/presentation/http/controllers/users.controller';
import { UsersApplicationModule } from './users-application.module';

@Module({
  imports: [UsersApplicationModule, AuthSecurityModule],
  controllers: [UsersController],
})
export class UsersContextModule {}

import { Module } from '@nestjs/common';
import { AuthController } from '@contexts/auth/presentation/http/controllers/auth.controller';
import { AuthSecurityModule } from './auth-security.module';

@Module({
  imports: [AuthSecurityModule],
  controllers: [AuthController],
  exports: [AuthSecurityModule],
})
export class AuthContextModule {}

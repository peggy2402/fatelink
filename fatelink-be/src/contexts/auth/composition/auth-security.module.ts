import { Module } from '@nestjs/common';
import { AuthApplicationModule } from './auth-application.module';
import { AdminGuard } from '@contexts/auth/presentation/http/guards/admin.guard';
import { JwtAuthGuard } from '@contexts/auth/presentation/http/guards/jwt-auth.guard';

@Module({
  imports: [AuthApplicationModule],
  providers: [JwtAuthGuard, AdminGuard],
  exports: [AuthApplicationModule, JwtAuthGuard, AdminGuard],
})
export class AuthSecurityModule {}

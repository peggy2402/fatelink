import { Module } from '@nestjs/common';
import { AiApplicationModule } from '@contexts/ai/composition/ai-application.module';
import { AuthSecurityModule } from '@contexts/auth/composition/auth-security.module';
import { AdminAiController } from '@contexts/admin/presentation/http/controllers/admin-ai.controller';
import { AdminAuthController } from '@contexts/admin/presentation/http/controllers/admin-auth.controller';
import { AdminConfigController } from '@contexts/admin/presentation/http/controllers/admin-config.controller';
import { AdminLogsController } from '@contexts/admin/presentation/http/controllers/admin-logs.controller';
import { AdminUsersController } from '@contexts/admin/presentation/http/controllers/admin-users.controller';
import { AdminApplicationModule } from './admin-application.module';

@Module({
  imports: [AdminApplicationModule, AiApplicationModule, AuthSecurityModule],
  controllers: [
    AdminAuthController,
    AdminConfigController,
    AdminUsersController,
    AdminAiController,
    AdminLogsController,
  ],
})
export class AdminContextModule {}

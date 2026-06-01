import {
  ADMIN_LOG_SERVICE,
  SUPPORT_NOTIFIER_SERVICE,
} from '@shared/kernel/injection-tokens';
import { Module } from '@nestjs/common';
import { DiscordSupportNotifierServiceImpl } from './services/discord-support-notifier.service.impl';
import { FileAdminLogServiceImpl } from './services/file-admin-log.service.impl';

@Module({
  providers: [
    {
      provide: SUPPORT_NOTIFIER_SERVICE,
      useClass: DiscordSupportNotifierServiceImpl,
    },
    {
      provide: ADMIN_LOG_SERVICE,
      useClass: FileAdminLogServiceImpl,
    },
  ],
  exports: [SUPPORT_NOTIFIER_SERVICE, ADMIN_LOG_SERVICE],
})
export class SupportInfrastructureModule {}

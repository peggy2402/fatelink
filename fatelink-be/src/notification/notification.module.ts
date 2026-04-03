import { Module } from '@nestjs/common';
import { NotificationService } from './notification.service';

@Module({
  providers: [NotificationService],
  exports: [NotificationService], // Export ra để MessageModule hoặc ChatGateway có thể gọi được
})
export class NotificationModule {}
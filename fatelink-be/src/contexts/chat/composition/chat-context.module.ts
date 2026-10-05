import { Module } from '@nestjs/common';
import { AuthApplicationModule } from '@contexts/auth/composition/auth-application.module';
import { ChatAiController } from '@contexts/chat/presentation/http/controllers/chat-ai.controller';
import { ChatHistoryController } from '@contexts/chat/presentation/http/controllers/chat-history.controller';
import { ChatGateway } from '@contexts/chat/presentation/websocket/gateways/chat.gateway';
import { ChatPresenceService } from '@contexts/chat/presentation/websocket/services/chat-presence.service';
import { UsersPersistenceModule } from '@contexts/users/infrastructure/users-persistence.module';
import { NotificationsModule } from '@shared/infrastructure/notifications/notifications.module';
import { ChatApplicationModule } from './chat-application.module';

@Module({
  imports: [
    ChatApplicationModule,
    AuthApplicationModule,
    UsersPersistenceModule,
    NotificationsModule,
  ],
  controllers: [ChatAiController, ChatHistoryController],
  providers: [ChatGateway, ChatPresenceService],
})
export class ChatContextModule {}

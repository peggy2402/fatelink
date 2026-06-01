import { Module } from '@nestjs/common';
import { AuthApplicationModule } from '@contexts/auth/composition/auth-application.module';
import { ChatAiController } from '@contexts/chat/presentation/http/controllers/chat-ai.controller';
import { ChatHistoryController } from '@contexts/chat/presentation/http/controllers/chat-history.controller';
import { ChatGateway } from '@contexts/chat/presentation/websocket/gateways/chat.gateway';
import { ChatPresenceService } from '@contexts/chat/presentation/websocket/services/chat-presence.service';
import { ChatApplicationModule } from './chat-application.module';

@Module({
  imports: [ChatApplicationModule, AuthApplicationModule],
  controllers: [ChatAiController, ChatHistoryController],
  providers: [ChatGateway, ChatPresenceService],
})
export class ChatContextModule {}

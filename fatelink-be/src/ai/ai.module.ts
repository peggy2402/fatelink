import { Module } from '@nestjs/common';
import { GeminiService } from './gemini.service';
import { ChatGateway } from './chat.gateway';
import { MessageModule } from '../message/message.module';
import { UsersModule } from '../users/users.module';

@Module({
  // Import MessageModule để ChatGateway có thể inject được MessageService
  imports: [MessageModule, UsersModule],
  providers: [GeminiService, ChatGateway],
  exports: [GeminiService],
})
export class AiModule {}
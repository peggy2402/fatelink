import { Module } from '@nestjs/common';
import { ChatGateway } from './chat.gateway';
import { MessageModule } from '../message/message.module';
import { UsersModule } from '../users/users.module';
import { AiService } from './ai.service';
import { AI_PROVIDER } from './providers/ai-provider.interface';
import { GeminiProvider } from './providers/gemini.provider';
import { OpenAiProvider } from './providers/openai.provider';

@Module({
  imports: [MessageModule, UsersModule],
  providers: [
    GeminiProvider,
    OpenAiProvider,
    {
      provide: AI_PROVIDER,
      useFactory: (gemini: GeminiProvider, openai: OpenAiProvider) => {
        // Trả về một mảng quy định THỨ TỰ AI PROVIDERS ĐƯỢC ƯU TIÊN GỌI (Fallback Chain)
        return [gemini, openai]; 
      },
      inject: [GeminiProvider, OpenAiProvider],
    },
    AiService,
    ChatGateway
  ],
  exports: [AiService],
})
export class AiModule {}
import { Module } from '@nestjs/common';
import { ChatGateway } from './chat.gateway';
import { MessageModule } from '../message/message.module';
import { UsersModule } from '../users/users.module';
import { AiService } from './ai.service';
import { AI_PROVIDER } from './providers/ai-provider.interface';
import { GeminiProvider } from './providers/gemini.provider';
import { OpenAiProvider } from './providers/openai.provider';
import { MockAiProvider } from './providers/mock-ai.provider';
import { LlamaProvider } from './providers/llama.provider';

@Module({
  imports: [MessageModule, UsersModule],
  providers: [
    GeminiProvider,
    OpenAiProvider,
    LlamaProvider,
    MockAiProvider,
    {
      provide: AI_PROVIDER,
      useFactory: (gemini: GeminiProvider, openai: OpenAiProvider, llama: LlamaProvider, mock: MockAiProvider) => {
        // Đưa Llama vào chuỗi Fallback
        return [gemini, llama, openai, mock]; 
      },
      inject: [GeminiProvider, OpenAiProvider, LlamaProvider, MockAiProvider],
    },
    AiService,
    ChatGateway
  ],
  exports: [AiService],
})
export class AiModule {}
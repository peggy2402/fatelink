import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ChatGateway } from './chat.gateway';
import { MessageModule } from '../message/message.module';
import { UsersModule } from '../users/users.module';
import { SystemConfig, SystemConfigSchema } from '../admin/schemas/system-config.schema';
import { AiService } from './ai.service';
import { AI_PROVIDER } from './providers/ai-provider.interface';
import { GeminiProvider } from './providers/gemini.provider';
import { OpenAiProvider } from './providers/openai.provider';
import { MockAiProvider } from './providers/mock-ai.provider';
import { LlamaProvider } from './providers/llama.provider';
import { HuggingFaceProvider } from './providers/huggingface.provider';

@Module({
  imports: [
    MessageModule, 
    UsersModule,
    MongooseModule.forFeature([{ name: SystemConfig.name, schema: SystemConfigSchema }])
  ],
  providers: [
    GeminiProvider,
    OpenAiProvider,
    LlamaProvider,
    HuggingFaceProvider,
    MockAiProvider,
    {
      provide: AI_PROVIDER,
      useFactory: (gemini: GeminiProvider, openai: OpenAiProvider, llama: LlamaProvider, hf: HuggingFaceProvider, mock: MockAiProvider) => {
        // Đưa HuggingFace vào chuỗi Fallback
        return [gemini, llama, openai, hf, mock]; 
      },
      inject: [GeminiProvider, OpenAiProvider, LlamaProvider, HuggingFaceProvider, MockAiProvider],
    },
    AiService,
    ChatGateway
  ],
  exports: [AiService],
})
export class AiModule {}
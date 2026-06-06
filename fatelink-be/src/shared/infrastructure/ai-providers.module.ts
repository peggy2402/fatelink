import { AI_PROVIDER } from '@shared/contracts/ai-provider.service';
import { Module } from '@nestjs/common';
import { GeminiProvider } from './providers/gemini.provider';
import { HuggingFaceProvider } from './providers/huggingface.provider';
import { LlamaProvider } from './providers/llama.provider';
import { MockAiProvider } from './providers/mock-ai.provider';
import { OpenAiProvider } from './providers/openai.provider';
import { ClaudeProvider } from './providers/claude.provider';

@Module({
  providers: [
    GeminiProvider,
    HuggingFaceProvider,
    LlamaProvider,
    MockAiProvider,
    OpenAiProvider,
    ClaudeProvider,
    {
      provide: AI_PROVIDER,
      useFactory: (
        gemini: GeminiProvider,
        huggingFace: HuggingFaceProvider,
        llama: LlamaProvider,
        mock: MockAiProvider,
        openai: OpenAiProvider,
        claude: ClaudeProvider,
      ) => [gemini, huggingFace, llama, mock, openai, claude],
      inject: [
        GeminiProvider,
        HuggingFaceProvider,
        LlamaProvider,
        MockAiProvider,
        OpenAiProvider,
        ClaudeProvider,
      ],
    },
  ],
  exports: [AI_PROVIDER],
})
export class SharedAiProvidersModule {}

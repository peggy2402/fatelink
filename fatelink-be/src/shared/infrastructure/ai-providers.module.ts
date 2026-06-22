import { AI_PROVIDER } from '@shared/contracts/ai-provider.service';
import { Module } from '@nestjs/common';
import { GeminiProvider } from './providers/gemini.provider';
import { HuggingFaceProvider } from './providers/huggingface.provider';
import { LlamaProvider } from './providers/llama.provider';
import { MockAiProvider } from './providers/mock-ai.provider';
import { OpenAiProvider } from './providers/openai.provider';
import { ClaudeProvider } from './providers/claude.provider';
import { GroqProvider } from './providers/groq.provider';

@Module({
  providers: [
    GeminiProvider,
    HuggingFaceProvider,
    LlamaProvider,
    MockAiProvider,
    OpenAiProvider,
    ClaudeProvider,
    GroqProvider,
    {
      provide: AI_PROVIDER,
      useFactory: (
        gemini: GeminiProvider,
        huggingFace: HuggingFaceProvider,
        llama: LlamaProvider,
        mock: MockAiProvider,
        openai: OpenAiProvider,
        claude: ClaudeProvider,
        groq: GroqProvider,
      ) => [gemini, huggingFace, llama, mock, openai, claude, groq],
      inject: [
        GeminiProvider,
        HuggingFaceProvider,
        LlamaProvider,
        MockAiProvider,
        OpenAiProvider,
        ClaudeProvider,
        GroqProvider,
      ],
    },
  ],
  exports: [AI_PROVIDER],
})
export class SharedAiProvidersModule {}

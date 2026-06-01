import { Injectable } from '@nestjs/common';
import type {
  AiProviderResponse,
  IAiProvider,
} from '@shared/contracts/ai-provider.service';

@Injectable()
export class MockAiProvider implements IAiProvider {
  readonly providerName = 'MockAI';

  async generateContent(prompt: string): Promise<AiProviderResponse> {
    return {
      rawText: `MOCK RESPONSE: ${prompt}`,
    };
  }
}

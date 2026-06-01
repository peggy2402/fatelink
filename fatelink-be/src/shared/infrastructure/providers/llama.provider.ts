import { Injectable } from '@nestjs/common';
import type {
  AiProviderResponse,
  IAiProvider,
} from '@shared/contracts/ai-provider.service';

@Injectable()
export class LlamaProvider implements IAiProvider {
  readonly providerName = 'Llama';

  async generateContent(): Promise<AiProviderResponse> {
    throw new Error('Llama provider is not configured yet.');
  }
}

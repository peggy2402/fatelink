import OpenAI from 'openai';
import { Injectable } from '@nestjs/common';
import type {
  AiProviderResponse,
  IAiProvider,
} from '@shared/contracts/ai-provider.service';

@Injectable()
export class OpenAiProvider implements IAiProvider {
  readonly providerName = 'OpenAI';
  private readonly client = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY,
    baseURL: process.env.OPENAI_BASE_URL,
  });

  async generateContent(
    prompt: string,
    modelName = 'gpt-4o-mini',
  ): Promise<AiProviderResponse> {
    const response = await this.client.chat.completions.create({
      model: modelName,
      messages: [{ role: 'user', content: prompt }],
    });

    return {
      rawText: response.choices[0]?.message?.content ?? '',
    };
  }
}

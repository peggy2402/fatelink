import { GoogleGenAI } from '@google/genai';
import { Injectable } from '@nestjs/common';
import type {
  AiProviderResponse,
  IAiProvider,
} from '@shared/contracts/ai-provider.service';

@Injectable()
export class GeminiProvider implements IAiProvider {
  readonly providerName = 'Gemini';
  private readonly client = new GoogleGenAI({
    apiKey: process.env.GEMINI_API_KEY,
  });

  async generateContent(
    prompt: string,
    modelName = 'gemini-2.5-flash',
  ): Promise<AiProviderResponse> {
    const response = await this.client.models.generateContent({
      model: modelName,
      contents: prompt,
    });

    return { rawText: response.text ?? '' };
  }
}

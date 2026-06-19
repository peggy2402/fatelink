import { Injectable } from '@nestjs/common';
import type {
  AiProviderResponse,
  IAiProvider,
} from '@shared/contracts/ai-provider.service';

@Injectable()
export class GroqProvider implements IAiProvider {
  readonly providerName = 'Groq';

  async generateContent(
    prompt: string,
    modelName = 'llama-3.1-8b-instant',
  ): Promise<AiProviderResponse> {
    const response = await fetch(
      'https://api.groq.com/openai/v1/chat/completions',
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${process.env.GROQ_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: modelName,
          messages: [{ role: 'user', content: prompt }],
        }),
      },
    );

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Groq API error: ${response.status} - ${errorText}`);
    }

    const data = (await response.json()) as {
      choices?: Array<{ message?: { content?: string } }>;
    };

    return {
      rawText: data.choices?.[0]?.message?.content ?? '',
    };
  }
}

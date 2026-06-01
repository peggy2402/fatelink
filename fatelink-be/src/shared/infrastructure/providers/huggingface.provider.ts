import { Injectable } from '@nestjs/common';
import type {
  AiProviderResponse,
  IAiProvider,
} from '@shared/contracts/ai-provider.service';

@Injectable()
export class HuggingFaceProvider implements IAiProvider {
  readonly providerName = 'HuggingFace';

  async generateContent(
    prompt: string,
    modelName = 'Qwen/Qwen2.5-7B-Instruct',
  ): Promise<AiProviderResponse> {
    const response = await fetch(
      `https://router.huggingface.co/v1/chat/completions`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${process.env.HUGGINGFACE_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: modelName,
          messages: [{ role: 'user', content: prompt }],
        }),
      },
    );

    if (!response.ok) {
      throw new Error(`HuggingFace API error: ${response.status}`);
    }

    const data = (await response.json()) as {
      choices?: Array<{ message?: { content?: string } }>;
    };

    return {
      rawText: data.choices?.[0]?.message?.content ?? '',
    };
  }
}

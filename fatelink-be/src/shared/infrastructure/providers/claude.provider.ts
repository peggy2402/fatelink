import { Injectable } from '@nestjs/common';
import type {
  AiProviderResponse,
  IAiProvider,
} from '@shared/contracts/ai-provider.service';

@Injectable()
export class ClaudeProvider implements IAiProvider {
  readonly providerName = 'Claude';

  async generateContent(
    prompt: string,
    modelName = 'claude-3-haiku-20240307',
  ): Promise<AiProviderResponse> {
    const baseUrl = process.env.ANTHROPIC_BASE_URL || 'https://api.anthropic.com';
    const endpoint = `${baseUrl.replace(/\/$/, '')}/v1/messages`;

    const response = await fetch(endpoint, {
      method: 'POST',
      headers: {
        'x-api-key': process.env.ANTHROPIC_API_KEY || '',
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        model: modelName,
        max_tokens: 2048,
        messages: [{ role: 'user', content: prompt }],
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Claude API error: ${response.status} - ${errorText}`);
    }

    const data = (await response.json()) as {
      content?: Array<{ text?: string }>;
    };

    return {
      rawText: data.content?.[0]?.text ?? '',
    };
  }
}
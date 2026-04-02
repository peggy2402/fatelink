// src/ai/providers/ai-provider.interface.ts

export interface AiProviderResponse {
  // Trả về text thô, việc parsing sẽ do AiService xử lý
  rawText: string;
}

export const AI_PROVIDER = 'AI_PROVIDER';

export interface IAiProvider {
  readonly providerName: string;
  generateContent(prompt: string): Promise<AiProviderResponse>;
}

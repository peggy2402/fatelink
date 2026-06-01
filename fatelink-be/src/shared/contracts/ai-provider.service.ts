export interface AiProviderResponse {
  rawText: string;
}

export const AI_PROVIDER = 'AI_PROVIDER';

export interface IAiProvider {
  readonly providerName: string;
  generateContent(
    prompt: string,
    modelName?: string,
  ): Promise<AiProviderResponse>;
}

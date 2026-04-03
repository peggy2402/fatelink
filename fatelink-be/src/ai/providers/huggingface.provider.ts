import { Injectable, Logger } from '@nestjs/common';
import { IAiProvider, AiProviderResponse } from './ai-provider.interface';

const API_TIMEOUT = 15000;

@Injectable()
export class HuggingFaceProvider implements IAiProvider {
  readonly providerName = 'HuggingFace';
  private readonly logger = new Logger(HuggingFaceProvider.name);
  private readonly apiKey: string;
  // Đổi sang model Qwen 2.5 7B: Rất nhẹ, khởi động nhanh trên bản Free và cực kỳ giỏi tiếng Việt
  private readonly endpoint = 'https://router.huggingface.co/hf-inference/v1/chat/completions'; 
  private readonly modelId = 'Qwen/Qwen2.5-7B-Instruct';

  constructor() {
    this.apiKey = process.env.HUGGINGFACE_API_KEY || '';
    if (!this.apiKey) {
      this.logger.warn('Chưa cấu hình HUGGINGFACE_API_KEY trong .env');
    }
  }

  async generateContent(prompt: string): Promise<AiProviderResponse> {
    if (!this.apiKey) throw new Error('HuggingFace API Key chưa được cấu hình.');

    try {
      const timeoutPromise = new Promise<never>((_, reject) =>
        setTimeout(() => reject(new Error(`Yêu cầu đến HuggingFace quá thời gian chờ ${API_TIMEOUT}ms.`)), API_TIMEOUT)
      );

      const fetchPromise = fetch(this.endpoint, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: this.modelId,
          messages: [{ role: 'user', content: prompt }],
          max_tokens: 500,
          temperature: 0.7
        })
      }).then(async res => {
        if (!res.ok) {
          const errBody = await res.text();
          this.logger.error(`Lỗi từ HuggingFace (${res.status}): ${errBody}`);
          throw new Error(`HuggingFace API Error (${res.status}): ${errBody}`);
        }
        return res.json();
      });

      const result: any = await Promise.race([fetchPromise, timeoutPromise]);
      
      const rawText = result.choices?.[0]?.message?.content || '';
      return { rawText };
    } catch (error: any) {
      throw error;
    }
  }
}
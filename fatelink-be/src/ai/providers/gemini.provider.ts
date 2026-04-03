// src/ai/providers/gemini.provider.ts
import { Injectable, Logger } from '@nestjs/common';
import { GoogleGenAI } from '@google/genai';
import { IAiProvider, AiProviderResponse } from './ai-provider.interface';

const API_TIMEOUT = 15000; // 15 giây

@Injectable()
export class GeminiProvider implements IAiProvider {
  readonly providerName = 'Gemini';
  private readonly logger = new Logger(GeminiProvider.name);
  private ai: GoogleGenAI;

  constructor() {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      this.logger.warn('Chưa cấu hình GEMINI_API_KEY, GeminiProvider sẽ không hoạt động.');
    }
    this.ai = new GoogleGenAI({
      apiKey: apiKey || 'DUMMY_KEY'
    });
  }

  async generateContent(prompt: string, modelName?: string): Promise<AiProviderResponse> {
    if (!process.env.GEMINI_API_KEY) {
      throw new Error('Gemini API Key chưa được cấu hình.');
    }

    let currentModelName = modelName || 'gemini-2.0-flash'; // Sử dụng model từ tham số truyền vào
    let retries = 3;
    let delayMs = 1000;

    for (let attempt = 1; attempt <= retries; attempt++) {
      try {
        // Tạo một promise sẽ reject sau khoảng thời gian timeout
        const timeoutPromise = new Promise<never>((_, reject) =>
          setTimeout(() => reject(new Error(`Yêu cầu đến Gemini quá thời gian chờ ${API_TIMEOUT}ms.`)), API_TIMEOUT)
        );

        // Chạy đua giữa lời gọi API và timeout
        const result = await Promise.race([
          this.ai.models.generateContent({
            model: currentModelName,
            contents: prompt,
            config: { temperature: 0.7, topP: 0.8 },
          }),
          timeoutPromise
        ]);

        // Ở thư viện mới, text được trả về trực tiếp
        const rawText = result.text || '';
        return { rawText };
      } catch (apiError: any) {
        const errorMessage = apiError?.message || '';

        if (errorMessage.includes('404') || errorMessage.includes('not found')) {
          this.logger.warn(`Model ${currentModelName} bị 404. Tự động đổi sang gemini-1.5-pro (Lần thử ${attempt})...`);
          currentModelName = 'gemini-1.5-pro';
          continue;
        }

        const isRateLimit = apiError?.status === 429 || errorMessage.includes('429') || errorMessage.includes('quota');
        if (isRateLimit && attempt < retries) {
          this.logger.warn(`Rate limit từ Gemini API. Đợi ${delayMs}ms và thử lại (Lần ${attempt})...`);
          await new Promise(resolve => setTimeout(resolve, delayMs));
          delayMs *= 2;
          continue;
        }
        throw apiError; // Ném lỗi ra ngoài nếu không xử lý được hoặc hết lần thử
      }
    }
    throw new Error('Đã hết số lần thử lại với Gemini Provider.');
  }
}

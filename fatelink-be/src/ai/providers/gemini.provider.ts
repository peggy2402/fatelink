// src/ai/providers/gemini.provider.ts
import { Injectable, Logger } from '@nestjs/common';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { IAiProvider, AiProviderResponse } from './ai-provider.interface';

@Injectable()
export class GeminiProvider implements IAiProvider {
  readonly providerName = 'Gemini';
  private readonly logger = new Logger(GeminiProvider.name);
  private ai: GoogleGenerativeAI;

  constructor() {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      this.logger.warn('Chưa cấu hình GEMINI_API_KEY, GeminiProvider sẽ không hoạt động.');
    }
    this.ai = new GoogleGenerativeAI(apiKey || 'DUMMY_KEY');
  }

  async generateContent(prompt: string): Promise<AiProviderResponse> {
    if (!process.env.GEMINI_API_KEY) {
      throw new Error('Gemini API Key chưa được cấu hình.');
    }

    let currentModelName = 'gemini-1.5-flash';
    let retries = 3;
    let delayMs = 1000;

    for (let attempt = 1; attempt <= retries; attempt++) {
      try {
        const model = this.ai.getGenerativeModel({
          model: currentModelName,
          generationConfig: { temperature: 0.7, topP: 0.8 },
        });

        const result = await model.generateContent(prompt);
        const rawText = result.response.text();
        return { rawText };
      } catch (apiError: any) {
        const errorMessage = apiError?.message || '';

        if (errorMessage.includes('404') || errorMessage.includes('not found')) {
          this.logger.warn(`Model ${currentModelName} bị 404. Tự động đổi sang gemini-pro (Lần thử ${attempt})...`);
          currentModelName = 'gemini-pro';
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

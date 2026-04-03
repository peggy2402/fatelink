// src/ai/providers/openai.provider.ts
import { Injectable, Logger } from '@nestjs/common';
import OpenAI from 'openai';
import { IAiProvider, AiProviderResponse } from './ai-provider.interface';

// Thời gian chờ tối đa cho một yêu cầu API (miliseconds)
const API_TIMEOUT = 15000; // 15 giây

@Injectable()
export class OpenAiProvider implements IAiProvider {
  readonly providerName = 'OpenAI';
  private readonly logger = new Logger(OpenAiProvider.name);
  private openai: OpenAI;

  constructor() {
    // Đổi sang dùng Groq API Key để dùng Llama 3 miễn phí và tốc độ cao
    const apiKey = process.env.GROQ_API_KEY || process.env.OPENAI_API_KEY;
    if (!apiKey) {
      this.logger.warn('Chưa cấu hình GROQ_API_KEY, OpenAiProvider sẽ không hoạt động.');
    }
    this.openai = new OpenAI({
      apiKey: apiKey || 'DUMMY_KEY',
      baseURL: 'https://api.groq.com/openai/v1', // Trỏ baseURL về hệ thống của Groq
    });
  }

  async generateContent(prompt: string): Promise<AiProviderResponse> {
    if (!this.openai.apiKey || this.openai.apiKey === 'DUMMY_KEY') {
      throw new Error('API Key chưa được cấu hình.');
    }

    try {
      // Tạo một promise sẽ reject sau khoảng thời gian timeout
      const timeoutPromise = new Promise<never>((_, reject) =>
        setTimeout(() => reject(new Error(`Yêu cầu đến OpenAI quá thời gian chờ ${API_TIMEOUT}ms.`)), API_TIMEOUT)
      );

      // Chạy đua giữa lời gọi API và timeout
      const response = await Promise.race([
        this.openai.chat.completions.create({
          model: 'llama-3.1-8b-instant', // Đã cập nhật sang model mới nhất của Groq
          messages: [{ role: 'user', content: prompt }],
          temperature: 0.7,
        }),
        timeoutPromise
      ]);


      const rawText = response.choices[0]?.message?.content || '';
      return { rawText };
    } catch (error: any) {
      this.logger.error(`Lỗi từ OpenAI API: ${error.message}`);
      throw error;
    }
  }
}
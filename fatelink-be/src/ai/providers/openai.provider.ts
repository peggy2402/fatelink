// src/ai/providers/openai.provider.ts
import { Injectable, Logger } from '@nestjs/common';
import OpenAI from 'openai';
import { IAiProvider, AiProviderResponse } from './ai-provider.interface';

@Injectable()
export class OpenAiProvider implements IAiProvider {
  readonly providerName = 'OpenAI';
  private readonly logger = new Logger(OpenAiProvider.name);
  private openai: OpenAI;

  constructor() {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      this.logger.warn('Chưa cấu hình OPENAI_API_KEY, OpenAiProvider sẽ không hoạt động.');
    }
    this.openai = new OpenAI({
      apiKey: apiKey || 'DUMMY_KEY',
    });
  }

  async generateContent(prompt: string): Promise<AiProviderResponse> {
    if (!process.env.OPENAI_API_KEY) {
      throw new Error('OpenAI API Key chưa được cấu hình.');
    }

    try {
      const response = await this.openai.chat.completions.create({
        model: 'gpt-4o-mini', // Dùng model nhanh và tiết kiệm chi phí
        messages: [{ role: 'user', content: prompt }],
        temperature: 0.7,
      });

      const rawText = response.choices[0]?.message?.content || '';
      return { rawText };
    } catch (error: any) {
      this.logger.error(`Lỗi từ OpenAI API: ${error.message}`);
      throw error;
    }
  }
}
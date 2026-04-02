// src/ai/ai.controller.ts
import { Controller, Post, Body } from '@nestjs/common';
import { AiService } from './ai.service';

@Controller('chat')
export class AiController {
  constructor(private readonly aiService: AiService) {}

  @Post('message')
  async handleIncomingMessage(
    @Body('message') message: string,
    @Body('history') history: any[] // Lịch sử lấy từ client hoặc truy vấn từ DB trước đó
  ) {
    // Format lịch sử về chuẩn của Google Generative AI
    const formattedHistory = this.aiService.formatHistoryForGemini(history || []);
    
    // Lấy phản hồi từ Faye AI
    const reply = await this.aiService.sendMessage(message, formattedHistory);

    return {
      success: true,
      reply: reply,
    };
  }
}

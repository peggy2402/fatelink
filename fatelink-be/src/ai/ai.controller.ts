// src/ai/ai.controller.ts
import { Controller, Post, Body } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBody } from '@nestjs/swagger';
import { AiService } from './ai.service';

@ApiTags('AI Chat')
@Controller('chat')
export class AiController {
  constructor(private readonly aiService: AiService) {}

  @Post('message')
  @ApiOperation({ summary: 'Gửi tin nhắn cho AI (Faye) và nhận phản hồi' })
  @ApiBody({ 
    schema: { 
      type: 'object', 
      properties: { 
        message: { type: 'string', example: 'Hôm nay mình hơi mệt mỏi chút...' },
        history: { type: 'array', items: { type: 'object' }, description: 'Mảng lịch sử chat truyền từ client' }
      } 
    } 
  })
  @ApiResponse({ status: 201, description: 'AI trả lời thành công.' })
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

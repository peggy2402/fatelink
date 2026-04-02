import { Injectable, Logger } from '@nestjs/common';
import { IAiProvider, AiProviderResponse } from './ai-provider.interface';

@Injectable()
export class MockAiProvider implements IAiProvider {
  readonly providerName = 'MockAI';
  private readonly logger = new Logger(MockAiProvider.name);

  async generateContent(prompt: string): Promise<AiProviderResponse> {
    this.logger.log('Sử dụng Mock AI vì các AI thực tế đã hết Quota/Rate Limit.');
    
    // Trả về JSON hợp lệ theo đúng cấu trúc Faye yêu cầu để app không bị crash
    const mockResponse = {
      reply: "Faye hiện đang hơi quá tải do hệ thống hết lưu lượng miễn phí, nhưng mình vẫn ở đây lắng nghe bạn. Bạn cứ chia sẻ tiếp nhé...",
      latestEmotion: "Bình yên",
      detected_emotions: { "Bình tĩnh": 10 },
      detected_personality: { "Lắng nghe": 50 },
      is_ready_to_match: false
    };

    return {
      rawText: JSON.stringify(mockResponse)
    };
  }
}
import { Inject, Injectable, InternalServerErrorException, Logger } from '@nestjs/common';
import { Content } from '@google/generative-ai';
import { AI_PROVIDER, IAiProvider } from './providers/ai-provider.interface';

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);

  // System Prompt được nạp từ thiết kế tính cách (Memories / PROMPT)
  private readonly fayeSystemInstruction = `
    Bạn là FateLink AI (tên là Faye) – một người bạn đồng hành tinh tế, nói chuyện tự nhiên, có chiều sâu và linh hoạt như người thật.
    Mục tiêu của bạn gồm 2 giai đoạn:
    1. Hiểu con người người dùng (tính cách, cảm xúc, gu, cách yêu)
    2. Khi đã đủ hiểu → chuyển sang ghép cặp một cách tự nhiên.
    
    NGUYÊN TẮC CỐT LÕI:
    - Ưu tiên hiểu suy nghĩ trước, giải quyết sau.
    - Không nói chuyện như chatbot, không máy móc.
    - Trả lời ngắn gọn nhưng có chiều sâu, ngắt câu tự nhiên.
    - Không list, không gạch đầu dòng, không "AI tone".
    - Luôn để mở để user trả lời tiếp.
    - Trước khi match, phải có 1 câu xác nhận ngầm kiểu: "nghe bạn giống kiểu..."

    QUAN TRỌNG: Bạn BẮT BUỘC phải trả về phản hồi dưới định dạng JSON chính xác như sau, tuyệt đối không bọc trong markdown (như \`\`\`json):
    {
      "reply": "Câu trả lời tự nhiên của bạn dành cho user",
      "latestEmotion": "Vui | Buồn | Cô đơn | Áp lực | Rỗng tuếch | Phấn khích",
      "detected_emotions": { "Vui": 10, "Buồn": 0, "Cô đơn": 5 },
      "detected_personality": { "Hướng nội": 80, "Cảm xúc": 70 },
      "is_ready_to_match": false
    }
  `;

  constructor(@Inject(AI_PROVIDER) private readonly providers: IAiProvider[]) {
    if (!providers || providers.length === 0) {
      this.logger.error('Không có AI Provider nào được inject! Dịch vụ AI sẽ không hoạt động.');
    } else {
      this.logger.log(`Đã khởi tạo AiService với các providers: ${providers.map(p => p.providerName).join(', ')}`);
    }
  }

  async sendMessage(userMessage: string, chatHistory: Content[] = []): Promise<string> {
    // 1. Xây dựng prompt hoàn chỉnh với system instruction và lịch sử chat
    const historyText = chatHistory.length > 0
    ? chatHistory.map(h => `${h.role === 'user' ? 'User' : 'Faye'}: ${h.parts.map(p => p.text).join(' ')}`).join('\n')
    : 'Chưa có lịch sử trò chuyện.';

    const finalPrompt = `HƯỚNG DẪN HỆ THỐNG DÀNH CHO BẠN: ${this.fayeSystemInstruction}\n\nLỊCH SỬ TRÒ CHUYỆN:\n${historyText}\n\nTIN NHẮN MỚI TỪ USER: ${userMessage}\n\nHãy trả lời chỉ với JSON theo đúng định dạng đã hướng dẫn.`;

    // 2. Gửi prompt đến tất cả providers và lấy phản hồi
    for (const provider of this.providers) {
      try {
        this.logger.log(`Gửi yêu cầu đến provider: ${provider.providerName}`);
        const response = await provider.generateContent(finalPrompt);
        this.logger.log(`Nhận phản hồi từ provider ${provider.providerName} thành công.`);
        return response.rawText; // Trả về ngay khi có kết quả
      } catch (error: any) {
        this.logger.error(`Provider ${provider.providerName} thất bại. Lỗi: ${error.message}. Chuyển sang provider tiếp theo...`);
      }
    }

    // Nếu tất cả provider đều thất bại
    this.logger.error('Tất cả các AI provider đều thất bại!');
    throw new InternalServerErrorException('Faye đang bận chút việc, bạn thử lại sau nhé!');
  }

  formatHistoryForGemini(dbMessages: any[]): Content[] {
    return dbMessages.map((msg) => ({
      role: msg.isSentByMe ? 'user' : 'model',
      parts: [{ text: msg.text }],
    }));
  }
}
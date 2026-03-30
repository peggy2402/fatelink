// src/ai/gemini.service.ts
import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { GoogleGenerativeAI, GenerativeModel, Content } from '@google/generative-ai';

@Injectable()
export class GeminiService {
  private ai: GoogleGenerativeAI;
  private model: GenerativeModel;

  // Đưa System Prompt từ PROMPT.md và SYSTEMREADME.md vào đây để "huấn luyện" tính cách AI
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
    - Bạn KHÔNG phải là người "hỏi thông tin" → bạn là người khiến user muốn nói về bản thân.
  `;

  constructor() {
    // Đảm bảo bạn đã thêm GEMINI_API_KEY vào file .env
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY is not defined in environment variables');
    }

    this.ai = new GoogleGenerativeAI(apiKey);
    
    // Sử dụng model 1.5 để hỗ trợ systemInstruction
    this.model = this.ai.getGenerativeModel({
      model: 'gemini-1.5-flash',
      systemInstruction: this.fayeSystemInstruction,
      generationConfig: {
        temperature: 0.7, // Nhiệt độ vừa phải để AI sáng tạo nhưng vẫn giữ được tính cách
        topP: 0.8,
        topK: 40,
      },
    });
  }

  /**
   * Hàm chat với AI có lưu trữ lịch sử cuộc hội thoại thực tế
   * @param userMessage Tin nhắn mới nhất của người dùng
   * @param chatHistory Lịch sử chat lấy từ Database (đã format chuẩn Gemini)
   */
  async sendMessage(userMessage: string, chatHistory: Content[] = []): Promise<string> {
    try {
      // Khởi tạo phiên chat với lịch sử đã có
      const chatSession = this.model.startChat({
        history: chatHistory,
      });

      // Gửi tin nhắn mới
      const result = await chatSession.sendMessage(userMessage);
      const responseText = result.response.text();

      return responseText;
    } catch (error) {
      console.error('Lỗi khi gọi Gemini API:', error);
      throw new InternalServerErrorException('Faye đang bận chút việc, bạn thử lại sau nhé!');
    }
  }

  /**
   * Hàm helper để chuyển đổi lịch sử từ DB của bạn sang định dạng của Gemini
   */
  formatHistoryForGemini(dbMessages: any[]): Content[] {
    return dbMessages.map((msg) => ({
      role: msg.isSentByMe ? 'user' : 'model',
      parts: [{ text: msg.text }],
    }));
  }
}

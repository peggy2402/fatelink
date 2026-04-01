import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { GoogleGenerativeAI, GenerativeModel, Content } from '@google/generative-ai';

@Injectable()
export class GeminiService {
  private ai: GoogleGenerativeAI;
  private model: GenerativeModel;

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
      "detected_emotion": "Vui | Buồn | Cô đơn | Áp lực | Rỗng tuếch | Phấn khích",
      "is_ready_to_match": true/false
    }
  `;

  constructor() {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) console.warn('⚠️ Chưa cấu hình GEMINI_API_KEY trong file .env');
    
    this.ai = new GoogleGenerativeAI(apiKey || 'DUMMY_KEY');
    
    this.model = this.ai.getGenerativeModel({
      model: 'gemini-1.5-flash',
      systemInstruction: this.fayeSystemInstruction,
      generationConfig: {
        temperature: 0.7,
        topP: 0.8,
        responseMimeType: "application/json",
      },
    });
  }

  async sendMessage(userMessage: string, chatHistory: Content[] = []): Promise<string> {
    try {
      const chatSession = this.model.startChat({ history: chatHistory });
      const result = await chatSession.sendMessage(userMessage);
      return result.response.text();
    } catch (error) {
      console.error('Lỗi khi gọi Gemini API:', error);
      throw new InternalServerErrorException('Faye đang bận chút việc, bạn thử lại sau nhé!');
    }
  }

  formatHistoryForGemini(dbMessages: any[]): Content[] {
    return dbMessages.map((msg) => ({
      role: msg.isSentByMe ? 'user' : 'model',
      parts: [{ text: msg.text }],
    }));
  }
}
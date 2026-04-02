import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { GoogleGenerativeAI, Content } from '@google/generative-ai';

@Injectable()
export class GeminiService {
  private ai: GoogleGenerativeAI;

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

  constructor() {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) console.warn('⚠️ Chưa cấu hình GEMINI_API_KEY trong file .env');
    
    this.ai = new GoogleGenerativeAI(apiKey || 'DUMMY_KEY');
  }

  async sendMessage(userMessage: string, chatHistory: Content[] = []): Promise<string> {
    try {
      // Thay vì dùng startChat dễ bị lỗi format, chúng ta chuyển lịch sử thành văn bản đưa vào prompt
      let historyText = '';
      if (chatHistory && chatHistory.length > 0) {
        historyText = chatHistory.map(msg => 
          `${msg.role === 'user' ? 'User' : 'Faye'}: ${msg.parts[0].text}`
        ).join('\n');
      }

      const finalPrompt = `
HƯỚNG DẪN HỆ THỐNG DÀNH CHO BẠN:
${this.fayeSystemInstruction}

Lịch sử trò chuyện gần đây:
${historyText}

Tin nhắn hiện tại của User: "${userMessage}"

Hãy phân tích và trả lời tuân thủ đúng định dạng JSON đã yêu cầu. Tuyệt đối không bọc trong thẻ markdown \`\`\`json.
      `;

      let currentModelName = 'gemini-1.5-flash';
      let retries = 3;
      let delayMs = 1000;
      
      for (let attempt = 1; attempt <= retries; attempt++) {
        try {
          // Khởi tạo model ở đây để linh hoạt đổi tên nếu bị lỗi 404
          const model = this.ai.getGenerativeModel({
            model: currentModelName,
            generationConfig: { temperature: 0.7, topP: 0.8 },
          });

          const result = await model.generateContent(finalPrompt);
          return result.response.text();
        } catch (apiError: any) {
          const errorMessage = apiError?.message || '';
          
          // NẾU LỖI 404 MODEL NOT FOUND -> TỰ ĐỘNG CHUYỂN SANG GEMINI-PRO (LUÔN HOẠT ĐỘNG)
          if (errorMessage.includes('404') || errorMessage.includes('not found')) {
            console.warn(`⚠️ Model ${currentModelName} bị 404. Tự động đổi sang gemini-pro (Lần thử ${attempt})...`);
            currentModelName = 'gemini-pro';
            continue; // Lập tức thử lại với model mới
          }

          const isRateLimit = apiError?.status === 429 || errorMessage.includes('429') || errorMessage.includes('quota') || errorMessage.includes('Too Many Requests');
          
          if (isRateLimit && attempt < retries) {
            console.warn(`⏳ Rate limit từ Gemini API. Đợi ${delayMs}ms và thử lại (Lần ${attempt})...`);
            await new Promise(resolve => setTimeout(resolve, delayMs));
            delayMs *= 2; // Tăng gấp đôi thời gian chờ cho lần thử sau (Exponential backoff)
            continue;
          }
          throw apiError; // Nếu không phải rate limit hoặc hết lượt thử, ném lỗi ra ngoài
        }
      }
      throw new Error('Max retries reached');
    } catch (error: any) {
      console.error('🔥 LỖI TẠI GEMINI SERVICE:');
      console.error(error?.message || error);
      if (!process.env.GEMINI_API_KEY) console.error('💡 Gợi ý: Kiểm tra lại xem bạn đã điền GEMINI_API_KEY trong file .env chưa?');
      
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
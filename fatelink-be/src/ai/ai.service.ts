import { Inject, Injectable, InternalServerErrorException, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Content } from '@google/generative-ai';
import { AI_PROVIDER, IAiProvider } from './providers/ai-provider.interface';
import { SystemConfig, SystemConfigDocument } from '../admin/schemas/system-config.schema';

export interface ProviderStatusResult {
  provider: string;
  status: string;
  ping?: string;
  error?: string;
}

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);

  // Biến lưu Cache cấu hình
  private cachedConfig: SystemConfigDocument | null = null;
  private cacheExpiration = 0;
  private readonly CACHE_TTL = 60000; // Cache 60 giây (1 phút) để giảm tải DB

  constructor(
    @Inject(AI_PROVIDER) private readonly providers: IAiProvider[],
    @InjectModel(SystemConfig.name) private configModel: Model<SystemConfigDocument>,
  ) {
    if (!providers || providers.length === 0) {
      this.logger.error('Không có AI Provider nào được inject! Dịch vụ AI sẽ không hoạt động.');
    } else {
      this.logger.log(`Đã khởi tạo AiService với các providers: ${providers.map(p => p.providerName).join(', ')}`);
    }
  }

  async sendMessage(userMessage: string, chatHistory: Content[] = []): Promise<string> {
    // 1. Lấy cấu hình System Prompt từ Cache hoặc Database
    let config = this.cachedConfig;
    if (!config || Date.now() > this.cacheExpiration) {
      config = await this.configModel.findOne().exec();
      this.cachedConfig = config;
      this.cacheExpiration = Date.now() + this.CACHE_TTL; // Gia hạn thêm 60s
    }

    const personaPrompt = config?.systemPrompt || 'Bạn là FateLink AI (tên là Faye) – một người bạn đồng hành tinh tế...';
    const knowledgePrompt = config?.additionalKnowledge ? `\n\n[KIẾN THỨC TÂM LÝ HỌC HÀNH VI ĐỂ BẠN THAM KHẢO ÁP DỤNG]:\n${config.additionalKnowledge}` : '';
    
    // Ép buộc JSON format (Phần này hardcode để bảo vệ logic backend không bị lỗi parse)
    const jsonInstruction = `\n\nQUAN TRỌNG: Bạn BẮT BUỘC phải trả về phản hồi dưới định dạng JSON chính xác như sau, tuyệt đối không bọc trong markdown (như \`\`\`json):\n{\n  "reply": "Câu trả lời tự nhiên của bạn dành cho user",\n  "latestEmotion": "Vui | Buồn | Cô đơn | Áp lực | Rỗng tuếch | Phấn khích",\n  "detected_emotions": { "Vui": 10, "Buồn": 0, "Cô đơn": 5 },\n  "detected_personality": { "Hướng nội": 80, "Cảm xúc": 70 },\n  "is_ready_to_match": false\n}`;
    
    const fayeSystemInstruction = personaPrompt + knowledgePrompt + jsonInstruction;

    // 2. Xây dựng prompt hoàn chỉnh với system instruction và lịch sử chat
    const historyText = chatHistory.length > 0
    ? chatHistory.map(h => `${h.role === 'user' ? 'User' : 'Faye'}: ${h.parts.map(p => p.text).join(' ')}`).join('\n')
    : 'Chưa có lịch sử trò chuyện.';

    const finalPrompt = `HƯỚNG DẪN HỆ THỐNG DÀNH CHO BẠN: ${fayeSystemInstruction}\n\nLỊCH SỬ TRÒ CHUYỆN:\n${historyText}\n\nTIN NHẮN MỚI TỪ USER: ${userMessage}\n\nHãy trả lời chỉ với JSON theo đúng định dạng đã hướng dẫn.`;

    // 3. Sắp xếp thứ tự gọi API dựa trên activeAiProvider từ DB
    let sortedProviders = [...this.providers];
    if (config?.activeAiProvider) {
      const activeIndex = sortedProviders.findIndex(p => 
        p.providerName.toLowerCase().includes(config!.activeAiProvider.toLowerCase())
      );
      if (activeIndex > 0) { // Nếu tìm thấy model ưu tiên và nó đang không đứng đầu
        const activeProvider = sortedProviders.splice(activeIndex, 1)[0];
        sortedProviders.unshift(activeProvider); // Đẩy model ưu tiên lên vị trí #1
      }
    }

    // 4. Gửi prompt theo chuỗi Fallback đã được sắp xếp thông minh
    for (const provider of sortedProviders) {
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

  // Hàm Ping check "sức khỏe" các provider AI
  async checkProvidersStatus() {
    const results: ProviderStatusResult[] = [];
    const testPrompt = 'Chỉ trả về chuỗi JSON sau: {"reply": "OK", "latestEmotion": "Bình tĩnh", "detected_emotions": {}, "detected_personality": {}, "is_ready_to_match": false}';
    
    for (const provider of this.providers) {
      const start = Date.now();
      try {
        await provider.generateContent(testPrompt);
        results.push({
          provider: provider.providerName,
          status: 'Online 🟢',
          ping: `${Date.now() - start}ms`
        });
      } catch (error: any) {
        results.push({
          provider: provider.providerName,
          status: 'Offline 🔴',
          error: error.message
        });
      }
    }
    return results;
  }

  formatHistoryForGemini(dbMessages: any[]): Content[] {
    return dbMessages.map((msg) => ({
      role: msg.isSentByMe ? 'user' : 'model',
      parts: [{ text: msg.text }],
    }));
  }
}
import { Inject, Injectable, InternalServerErrorException, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Content } from '@google/generative-ai';
import { AI_PROVIDER, IAiProvider } from './providers/ai-provider.interface';
import { SystemConfig, SystemConfigDocument } from '../admin/schemas/system-config.schema';
import { AiModel, AiModelDocument } from '../admin/schemas/ai-model.schema';

export interface ProviderStatusResult {
  provider: string;
  modelId?: string;
  displayName?: string;
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
    @InjectModel(AiModel.name) private aiModelModel: Model<AiModelDocument>,
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

    // 3. Lấy danh sách Model động từ Database, ưu tiên từ cao đến thấp
    const activeModels = await this.aiModelModel.find({ isEnabled: true }).sort({ priority: 1 }).exec();

    // 4. Gửi request theo chuỗi (Fallback)
    if (activeModels.length > 0) {
      for (const dbModel of activeModels) {
        const provider = this.providers.find(p => p.providerName === dbModel.providerName);
        if (provider) {
          try {
            this.logger.log(`Gửi yêu cầu đến ${provider.providerName} (Model: ${dbModel.modelId})`);
            const response = await provider.generateContent(finalPrompt, dbModel.modelId);
            return response.rawText;
          } catch (error: any) {
            this.logger.error(`Model ${dbModel.modelId} thất bại. Lỗi: ${error.message}. Chuyển sang model tiếp theo...`);
          }
        }
      }
    } else {
      // Fallback an toàn nếu DB rỗng
      for (const provider of this.providers) {
        try {
          const response = await provider.generateContent(finalPrompt);
          return response.rawText;
        } catch(e) {}
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
    
    const dbModels = await this.aiModelModel.find().exec();

    // Duyệt qua tất cả các Provider đang có trong hệ thống
    for (const provider of this.providers) {
      // Lấy tất cả các model thuộc provider này từ Database
      const providerModels = dbModels.filter(m => m.providerName === provider.providerName);

      if (providerModels.length === 0) {
        // Nếu provider không có model nào được cấu hình
        results.push({
          provider: provider.providerName,
          modelId: undefined,
          displayName: undefined,
          status: 'N/A',
          error: 'Chưa cấu hình model nào'
        });
        continue;
      }

      // Nếu có model, tiến hành ping từng model một
      for (const dbModel of providerModels) {
        const start = Date.now();
        try {
          await provider.generateContent(testPrompt, dbModel.modelId);
          results.push({
            provider: dbModel.providerName,
            modelId: dbModel.modelId,
            displayName: dbModel.displayName,
            status: 'SUCCESS',
            ping: `${Date.now() - start}ms`
          });
        } catch (error: any) {
          results.push({
            provider: dbModel.providerName,
            modelId: dbModel.modelId,
            displayName: dbModel.displayName,
            status: 'ERROR',
            error: error.message
          });
        }
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
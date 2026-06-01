import type {
  ChatHistoryItem,
  SendChatMessageCommand,
} from '@contexts/chat/application/contracts/chat.commands';
import type { SendAiMessageHandler } from '@contexts/chat/application/contracts/chat.handlers';
import { InternalApplicationError } from '@shared/errors/application-error';
import type { IAiProvider } from '@shared/contracts/ai-provider.service';
import type { AiModelCatalogRepository } from '@contexts/admin/domain/repositories/ai-model-catalog.repository';
import type { SystemConfigRepository } from '@contexts/admin/domain/repositories/system-config.repository';

export class SendAiMessageUseCase implements SendAiMessageHandler {
  private cachedSystemPrompt = '';
  private cachedKnowledge = '';
  private cacheExpiration = 0;
  private readonly cacheTtlMs = 60000;

  constructor(
    private readonly providers: IAiProvider[],
    private readonly aiModelCatalogRepository: AiModelCatalogRepository,
    private readonly systemConfigRepository: SystemConfigRepository,
  ) {}

  async execute(input: SendChatMessageCommand): Promise<string> {
    const finalPrompt = await this.buildPrompt(
      input.message,
      input.history || [],
    );
    const activeModels = (await this.aiModelCatalogRepository.getAiModels())
      .filter((model) => model.isEnabled)
      .sort((a, b) => a.priority - b.priority);

    if (activeModels.length > 0) {
      for (const model of activeModels) {
        const provider = this.providers.find(
          (item) => item.providerName === model.providerName,
        );
        if (!provider) {
          continue;
        }

        try {
          const response = await provider.generateContent(
            finalPrompt,
            model.modelId,
          );
          return response.rawText;
        } catch (error) {
          void error;
        }
      }
    }

    for (const provider of this.providers) {
      try {
        const response = await provider.generateContent(finalPrompt);
        return response.rawText;
      } catch (error) {
        void error;
      }
    }

    throw new InternalApplicationError(
      'Faye đang bận chút việc, bạn thử lại sau nhé!',
    );
  }

  private async buildPrompt(message: string, history: ChatHistoryItem[]) {
    if (Date.now() > this.cacheExpiration) {
      const config = await this.systemConfigRepository.getConfig();
      this.cachedSystemPrompt =
        config.systemPrompt ||
        'Bạn là FateLink AI (tên là Faye) - một người bạn đồng hành tinh tế...';
      this.cachedKnowledge = config.additionalKnowledge || '';
      this.cacheExpiration = Date.now() + this.cacheTtlMs;
    }

    const knowledgePrompt = this.cachedKnowledge
      ? `\n\n[KIEN THUC TAM LY HOC HANH VI DE BAN THAM KHAO AP DUNG]:\n${this.cachedKnowledge}`
      : '';
    const jsonInstruction = `\n\nQUAN TRONG: Ban BAT BUOC phai tra ve phan hoi duoi dinh dang JSON chinh xac nhu sau, tuyet doi khong boc trong markdown:\n{\n  "reply": "Cau tra loi tu nhien cua ban danh cho user",\n  "latestEmotion": "Vui | Buon | Co don | Ap luc | Rong tuech | Phan khich",\n  "detected_emotions": { "stress": 0, "loneliness": 5, "sadness": 0, "calmness": 5, "warmth": 5, "happiness": 5 },\n  "detected_personality": [5, 5, 5],\n  "is_ready_to_match": false\n}`;
    const historyText =
      history.length > 0
        ? history
            .map((item) => `${item.isSentByMe ? 'User' : 'Faye'}: ${item.text}`)
            .join('\n')
        : 'Chua co lich su tro chuyen.';

    return `HUONG DAN HE THONG DANH CHO BAN: ${
      this.cachedSystemPrompt
    }${knowledgePrompt}${jsonInstruction}\n\nLICH SU TRO CHUYEN:\n${historyText}\n\nTIN NHAN MOI TU USER: ${message}\n\nHay tra loi chi voi JSON theo dung dinh dang da huong dan.`;
  }
}

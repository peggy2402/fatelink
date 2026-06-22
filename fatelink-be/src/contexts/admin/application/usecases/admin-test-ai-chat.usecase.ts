import { InternalApplicationError } from '@shared/errors/application-error';
import type { IAiProvider } from '@shared/contracts/ai-provider.service';
import type { AiModelCatalogRepository } from '@contexts/admin/domain/repositories/ai-model-catalog.repository';
import type { SystemConfigRepository } from '@contexts/admin/domain/repositories/system-config.repository';

type HistoryItem = { role: string; text: string };
type TestAiChatCommand = {
  message: string;
  modelId?: string;
  providerName?: string;
  history?: HistoryItem[];
};

export class AdminTestAiChatUseCase {
  private cachedSystemPrompt = '';
  private cachedKnowledge = '';
  private cacheExpiration = 0;
  private readonly cacheTtlMs = 60000;

  constructor(
    private readonly providers: IAiProvider[],
    private readonly aiModelCatalogRepository: AiModelCatalogRepository,
    private readonly systemConfigRepository: SystemConfigRepository,
  ) {}

  async execute(input: TestAiChatCommand): Promise<string> {
    const finalPrompt = await this.buildPrompt(input.message, input.history);

    if (input.modelId && input.providerName) {
      const provider = this.providers.find(
        (item) => item.providerName === input.providerName,
      );
      if (provider) {
        try {
          const response = await provider.generateContent(
            finalPrompt,
            input.modelId,
          );
          return response.rawText;
        } catch (error) {
          // Specific model failed → fallback to auto-priority
          void error;
        }
      }
    }

    const activeModels = (await this.aiModelCatalogRepository.getAiModels())
      .filter((model) => model.isEnabled)
      .sort((a, b) => a.priority - b.priority);

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

  private async buildPrompt(message: string, history?: HistoryItem[]) {
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

    const jsonInstruction = `\n\nQUAN TRONG: Ban BAT BUOC phai tra ve phan hoi duoi dinh dang JSON chinh xac nhu sau, tuyet doi khong boc trong markdown, chi tra ve JSON thuan:\n{\n  "reply": "Cau tra loi tu nhien cua ban danh cho user, ngan gon, khong phan tich",\n  "latestEmotion": "Vui | Buon | Co don | Ap luc | Rong tuech | Phan khich",\n  "detected_emotions": { "stress": 0, "loneliness": 0, "sadness": 0, "calmness": 0, "warmth": 0, "happiness": 0 },\n  "detected_personality": [5, 5, 5],\n  "is_ready_to_match": false\n}`;

    const historyText =
      history && history.length > 0
        ? history.map((item) => `${item.role === 'user' ? 'User' : 'Faye'}: ${item.text}`).join('\n')
        : 'Chua co tin nhan truoc do.';

    return `HUONG DAN HE THONG DANH CHO BAN: ${this.cachedSystemPrompt}${knowledgePrompt}${jsonInstruction}\n\nLICH SU TRO CHUYEN:\n${historyText}\n\nTIN NHAN MOI TU USER: ${message}\n\nHay tra loi chi voi JSON theo dung dinh dang da huong dan, khong them bat ky text nao khac ngoai JSON.`;
  }
}

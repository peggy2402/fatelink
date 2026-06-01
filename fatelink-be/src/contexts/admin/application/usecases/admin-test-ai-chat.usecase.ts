import { InternalApplicationError } from '@shared/errors/application-error';
import type { IAiProvider } from '@shared/contracts/ai-provider.service';
import type { AiModelCatalogRepository } from '@contexts/admin/domain/repositories/ai-model-catalog.repository';
import type { SystemConfigRepository } from '@contexts/admin/domain/repositories/system-config.repository';

type TestAiChatCommand = {
  message: string;
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
    const finalPrompt = await this.buildPrompt(input.message);
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

  private async buildPrompt(message: string) {
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

    return `HUONG DAN HE THONG DANH CHO BAN: ${this.cachedSystemPrompt}${knowledgePrompt}\n\nTIN NHAN TEST TU ADMIN: ${message}`;
  }
}

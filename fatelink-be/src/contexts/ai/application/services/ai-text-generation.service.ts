import type { AiModelCatalogRepository } from '@contexts/admin/domain/repositories/ai-model-catalog.repository';
import type { IAiProvider } from '@shared/contracts/ai-provider.service';
import { InternalApplicationError } from '@shared/errors/application-error';

export class AiTextGenerationService {
  constructor(
    private readonly providers: IAiProvider[],
    private readonly aiModelCatalogRepository: AiModelCatalogRepository,
  ) {}

  async generate(prompt: string): Promise<string> {
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
        const response = await provider.generateContent(prompt, model.modelId);
        return response.rawText;
      } catch (error) {
        void error;
      }
    }

    for (const provider of this.providers) {
      try {
        const response = await provider.generateContent(prompt);
        return response.rawText;
      } catch (error) {
        void error;
      }
    }

    throw new InternalApplicationError(
      'Faye đang bận chút việc, bạn thử lại sau nhé!',
    );
  }
}

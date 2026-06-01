import type { IAiProvider } from '@shared/contracts/ai-provider.service';
import type { AiModelCatalogRepository } from '@contexts/admin/domain/repositories/ai-model-catalog.repository';

export class CheckAiProvidersStatusUseCase {
  constructor(
    private readonly providers: IAiProvider[],
    private readonly aiModelCatalogRepository: AiModelCatalogRepository,
  ) {}

  async execute() {
    const results: Array<Record<string, string | undefined>> = [];
    const testPrompt =
      'Chi tra ve chuoi JSON sau: {"reply":"OK","latestEmotion":"Binh tinh","detected_emotions":{},"detected_personality":[],"is_ready_to_match":false}';
    const models = await this.aiModelCatalogRepository.getAiModels();

    for (const provider of this.providers) {
      const providerModels = models.filter(
        (model) => model.providerName === provider.providerName,
      );

      if (providerModels.length === 0) {
        results.push({
          provider: provider.providerName,
          status: 'N/A',
          error: 'Chưa cấu hình model nào',
        });
        continue;
      }

      for (const model of providerModels) {
        const start = Date.now();
        try {
          await provider.generateContent(testPrompt, model.modelId);
          results.push({
            provider: model.providerName,
            modelId: model.modelId,
            displayName: model.displayName,
            status: 'SUCCESS',
            ping: `${Date.now() - start}ms`,
          });
        } catch (error) {
          results.push({
            provider: model.providerName,
            modelId: model.modelId,
            displayName: model.displayName,
            status: 'ERROR',
            error: error instanceof Error ? error.message : String(error),
          });
        }
      }
    }

    return results;
  }
}

import type { AiModelCatalogRepository } from '@contexts/admin/domain/repositories/ai-model-catalog.repository';

export class GetAiModelsUseCase {
  constructor(
    private readonly aiModelCatalogRepository: AiModelCatalogRepository,
  ) {}

  execute() {
    return this.aiModelCatalogRepository.getAiModels();
  }
}

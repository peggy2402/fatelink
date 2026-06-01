import type { AiModelCatalogRepository } from '@contexts/admin/domain/repositories/ai-model-catalog.repository';

export class DeleteAiModelUseCase {
  constructor(
    private readonly aiModelCatalogRepository: AiModelCatalogRepository,
  ) {}

  execute(input: { id: string }) {
    return this.aiModelCatalogRepository.deleteAiModel(input.id);
  }
}

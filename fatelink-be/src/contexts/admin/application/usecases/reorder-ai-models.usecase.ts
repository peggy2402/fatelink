import type { ReorderAiModelsCommand } from '@contexts/admin/application/contracts/admin.commands';
import type { AiModelCatalogRepository } from '@contexts/admin/domain/repositories/ai-model-catalog.repository';

export class ReorderAiModelsUseCase {
  constructor(
    private readonly aiModelCatalogRepository: AiModelCatalogRepository,
  ) {}

  execute(input: ReorderAiModelsCommand) {
    return this.aiModelCatalogRepository.reorderAiModels(input);
  }
}

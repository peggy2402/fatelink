import type { UpdateAiModelCommand } from '@contexts/admin/application/contracts/admin.commands';
import type { AiModelCatalogRepository } from '@contexts/admin/domain/repositories/ai-model-catalog.repository';

export class UpdateAiModelUseCase {
  constructor(
    private readonly aiModelCatalogRepository: AiModelCatalogRepository,
  ) {}

  execute(input: UpdateAiModelCommand) {
    return this.aiModelCatalogRepository.updateAiModel(input);
  }
}

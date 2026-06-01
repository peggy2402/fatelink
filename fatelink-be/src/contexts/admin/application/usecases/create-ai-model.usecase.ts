import type { CreateAiModelCommand } from '@contexts/admin/application/contracts/admin.commands';
import type { AiModelCatalogRepository } from '@contexts/admin/domain/repositories/ai-model-catalog.repository';

export class CreateAiModelUseCase {
  constructor(
    private readonly aiModelCatalogRepository: AiModelCatalogRepository,
  ) {}

  execute(input: CreateAiModelCommand) {
    return this.aiModelCatalogRepository.createAiModel(input);
  }
}

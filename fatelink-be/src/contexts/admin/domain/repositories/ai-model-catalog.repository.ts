import type {
  CreateAiModelCommand,
  ReorderAiModelsCommand,
  UpdateAiModelCommand,
} from '@contexts/admin/application/contracts/admin.commands';
import type { ReorderAiModelsResult } from '@contexts/admin/application/contracts/admin.results';
import { type AiModel } from '@contexts/admin/domain/entities/ai-model';

export interface AiModelCatalogRepository {
  getAiModels(): Promise<AiModel[]>;
  createAiModel(command: CreateAiModelCommand): Promise<AiModel>;
  updateAiModel(command: UpdateAiModelCommand): Promise<AiModel | null>;
  deleteAiModel(id: string): Promise<AiModel | null>;
  reorderAiModels(
    command: ReorderAiModelsCommand,
  ): Promise<ReorderAiModelsResult>;
}

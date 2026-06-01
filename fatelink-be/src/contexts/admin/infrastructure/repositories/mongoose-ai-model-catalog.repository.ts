import type {
  CreateAiModelCommand,
  ReorderAiModelsCommand,
  UpdateAiModelCommand,
} from '@contexts/admin/application/contracts/admin.commands';
import type { ReorderAiModelsResult } from '@contexts/admin/application/contracts/admin.results';
import type { AiModel as DomainAiModel } from '@contexts/admin/domain/entities/ai-model';
import type { AiModelCatalogRepository } from '@contexts/admin/domain/repositories/ai-model-catalog.repository';
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { HydratedDocument, Model } from 'mongoose';
import { AiModel, AiModelDocument } from '../models/ai-model.model';

@Injectable()
export class MongooseAiModelCatalogRepository implements AiModelCatalogRepository {
  constructor(
    @InjectModel(AiModel.name)
    private readonly aiModel: Model<AiModelDocument>,
  ) {}

  async getAiModels(): Promise<DomainAiModel[]> {
    const models = await this.aiModel.find().sort({ priority: 1 }).exec();
    return models.map((item) => this.toAiModel(item));
  }

  async createAiModel(dto: CreateAiModelCommand): Promise<DomainAiModel> {
    const model = await new this.aiModel(dto).save();
    return this.toAiModel(model);
  }

  async updateAiModel(
    command: UpdateAiModelCommand,
  ): Promise<DomainAiModel | null> {
    return this.aiModel
      .findByIdAndUpdate(command.id, command, { new: true })
      .exec()
      .then((item) => (item ? this.toAiModel(item) : null));
  }

  async deleteAiModel(id: string): Promise<DomainAiModel | null> {
    return this.aiModel
      .findByIdAndDelete(id)
      .exec()
      .then((item) => (item ? this.toAiModel(item) : null));
  }

  async reorderAiModels(
    command: ReorderAiModelsCommand,
  ): Promise<ReorderAiModelsResult> {
    const bulkOps = command.modelIds.map((id, index) => ({
      updateOne: {
        filter: { _id: id },
        update: { priority: index },
      },
    }));
    const result = await this.aiModel.bulkWrite(bulkOps);
    return {
      reorderedCount: result.modifiedCount ?? command.modelIds.length,
    };
  }

  private toAiModel(document: HydratedDocument<AiModel>): DomainAiModel {
    return {
      id: document._id.toString(),
      modelId: document.modelId,
      providerName: document.providerName,
      displayName: document.displayName,
      isEnabled: document.isEnabled,
      priority: document.priority,
    };
  }
}

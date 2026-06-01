import type { UpdateSystemConfigCommand } from '@contexts/admin/application/contracts/admin.commands';
import type { SystemConfig as DomainSystemConfig } from '@contexts/admin/domain/entities/system-config';
import type { SystemConfigRepository } from '@contexts/admin/domain/repositories/system-config.repository';
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { HydratedDocument, Model } from 'mongoose';
import {
  SystemConfig,
  SystemConfigDocument,
} from '../models/system-config.model';

@Injectable()
export class MongooseSystemConfigRepository implements SystemConfigRepository {
  constructor(
    @InjectModel(SystemConfig.name)
    private readonly configModel: Model<SystemConfigDocument>,
  ) {}

  async getConfig(): Promise<DomainSystemConfig> {
    let config = await this.configModel.findOne().exec();
    if (!config) {
      config = await this.configModel.create({});
    }
    return this.toSystemConfig(config);
  }

  async updateConfig(
    updateData: UpdateSystemConfigCommand,
  ): Promise<DomainSystemConfig | null> {
    const config = await this.configModel.findOne().exec();
    const ensuredConfig = config ?? (await this.configModel.create({}));
    return this.configModel
      .findByIdAndUpdate(ensuredConfig._id, updateData, { new: true })
      .exec()
      .then((item) => (item ? this.toSystemConfig(item) : null));
  }

  private toSystemConfig(
    document: HydratedDocument<SystemConfig>,
  ): DomainSystemConfig {
    return {
      id: document._id.toString(),
      systemPrompt: document.systemPrompt,
      additionalKnowledge: document.additionalKnowledge,
      onboardingMessageLimit: document.onboardingMessageLimit,
    };
  }
}

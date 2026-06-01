import {
  AI_MODEL_CATALOG_REPOSITORY,
  SYSTEM_CONFIG_REPOSITORY,
} from '@shared/kernel/injection-tokens';
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AiModel, AiModelSchema } from './models/ai-model.model';
import { SystemConfig, SystemConfigSchema } from './models/system-config.model';
import { MongooseAiModelCatalogRepository } from './repositories/mongoose-ai-model-catalog.repository';
import { MongooseSystemConfigRepository } from './repositories/mongoose-system-config.repository';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: SystemConfig.name, schema: SystemConfigSchema },
      { name: AiModel.name, schema: AiModelSchema },
    ]),
  ],
  providers: [
    {
      provide: SYSTEM_CONFIG_REPOSITORY,
      useClass: MongooseSystemConfigRepository,
    },
    {
      provide: AI_MODEL_CATALOG_REPOSITORY,
      useClass: MongooseAiModelCatalogRepository,
    },
  ],
  exports: [SYSTEM_CONFIG_REPOSITORY, AI_MODEL_CATALOG_REPOSITORY],
})
export class AdminPersistenceModule {}

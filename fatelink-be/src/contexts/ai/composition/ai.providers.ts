import {
  AI_PROVIDER,
  type IAiProvider,
} from '@shared/contracts/ai-provider.service';
import { AiTextGenerationService } from '@contexts/ai/application/services/ai-text-generation.service';
import { CheckAiProvidersStatusUseCase } from '@contexts/ai/application/usecases/check-ai-providers-status.usecase';
import { AI_APPLICATION_TOKENS } from './ai.tokens';
import { AI_MODEL_CATALOG_REPOSITORY } from '@shared/kernel/injection-tokens';
import type { AiModelCatalogRepository } from '@contexts/admin/domain/repositories/ai-model-catalog.repository';
import type { Provider } from '@nestjs/common';

export const aiUseCaseProviders: Provider[] = [
  {
    provide: AI_APPLICATION_TOKENS.checkProvidersStatus,
    useFactory: (
      providers: IAiProvider[],
      aiModelCatalogRepository: AiModelCatalogRepository,
    ) => new CheckAiProvidersStatusUseCase(providers, aiModelCatalogRepository),
    inject: [AI_PROVIDER, AI_MODEL_CATALOG_REPOSITORY],
  },
  {
    provide: AI_APPLICATION_TOKENS.generateText,
    useFactory: (
      providers: IAiProvider[],
      aiModelCatalogRepository: AiModelCatalogRepository,
    ) => new AiTextGenerationService(providers, aiModelCatalogRepository),
    inject: [AI_PROVIDER, AI_MODEL_CATALOG_REPOSITORY],
  },
];

export const aiUseCases = [
  AI_APPLICATION_TOKENS.checkProvidersStatus,
  AI_APPLICATION_TOKENS.generateText,
];

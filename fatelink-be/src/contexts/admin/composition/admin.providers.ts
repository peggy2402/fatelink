import type { AdminCredentialService } from '@shared/contracts/admin-credential.service';
import type { AdminLogService } from '@shared/contracts/admin-log.service';
import {
  AI_PROVIDER,
  type IAiProvider,
} from '@shared/contracts/ai-provider.service';
import type { TokenService } from '@shared/contracts/token.service';
import { AdminBanUserUseCase } from '@contexts/admin/application/usecases/admin-ban-user.usecase';
import { AdminListUsersUseCase } from '@contexts/admin/application/usecases/admin-list-users.usecase';
import { AdminLoginUseCase } from '@contexts/admin/application/usecases/admin-login.usecase';
import { AdminTestAiChatUseCase } from '@contexts/admin/application/usecases/admin-test-ai-chat.usecase';
import { CreateAiModelUseCase } from '@contexts/admin/application/usecases/create-ai-model.usecase';
import { DeleteAiModelUseCase } from '@contexts/admin/application/usecases/delete-ai-model.usecase';
import { GetAdminLogFileUseCase } from '@contexts/admin/application/usecases/get-admin-log-file.usecase';
import { GetAiModelsUseCase } from '@contexts/admin/application/usecases/get-ai-models.usecase';
import { GetSystemConfigUseCase } from '@contexts/admin/application/usecases/get-system-config.usecase';
import { ReorderAiModelsUseCase } from '@contexts/admin/application/usecases/reorder-ai-models.usecase';
import { SaveAdminLogUseCase } from '@contexts/admin/application/usecases/save-admin-log.usecase';
import { UpdateAiModelUseCase } from '@contexts/admin/application/usecases/update-ai-model.usecase';
import { UpdateSystemConfigUseCase } from '@contexts/admin/application/usecases/update-system-config.usecase';
import { ADMIN_APPLICATION_TOKENS } from './admin.tokens';
import {
  ADMIN_CREDENTIAL_SERVICE,
  ADMIN_LOG_SERVICE,
  AI_MODEL_CATALOG_REPOSITORY,
  SYSTEM_CONFIG_REPOSITORY,
  TOKEN_SERVICE,
  USER_REPOSITORY,
} from '@shared/kernel/injection-tokens';
import type { AiModelCatalogRepository } from '@contexts/admin/domain/repositories/ai-model-catalog.repository';
import type { SystemConfigRepository } from '@contexts/admin/domain/repositories/system-config.repository';
import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';
import type { Provider } from '@nestjs/common';

export const adminUseCaseProviders: Provider[] = [
  {
    provide: ADMIN_APPLICATION_TOKENS.banUser,
    useFactory: (userRepository: UserRepository) =>
      new AdminBanUserUseCase(userRepository),
    inject: [USER_REPOSITORY],
  },
  {
    provide: ADMIN_APPLICATION_TOKENS.listUsers,
    useFactory: (userRepository: UserRepository) =>
      new AdminListUsersUseCase(userRepository),
    inject: [USER_REPOSITORY],
  },
  {
    provide: ADMIN_APPLICATION_TOKENS.login,
    useFactory: (
      credentials: AdminCredentialService,
      tokenService: TokenService,
    ) => new AdminLoginUseCase(credentials, tokenService),
    inject: [ADMIN_CREDENTIAL_SERVICE, TOKEN_SERVICE],
  },
  {
    provide: ADMIN_APPLICATION_TOKENS.testAiChat,
    useFactory: (
      providers: IAiProvider[],
      aiModelCatalogRepository: AiModelCatalogRepository,
      systemConfigRepository: SystemConfigRepository,
    ) =>
      new AdminTestAiChatUseCase(
        providers,
        aiModelCatalogRepository,
        systemConfigRepository,
      ),
    inject: [
      AI_PROVIDER,
      AI_MODEL_CATALOG_REPOSITORY,
      SYSTEM_CONFIG_REPOSITORY,
    ],
  },
  {
    provide: ADMIN_APPLICATION_TOKENS.createAiModel,
    useFactory: (aiModelCatalogRepository: AiModelCatalogRepository) =>
      new CreateAiModelUseCase(aiModelCatalogRepository),
    inject: [AI_MODEL_CATALOG_REPOSITORY],
  },
  {
    provide: ADMIN_APPLICATION_TOKENS.deleteAiModel,
    useFactory: (aiModelCatalogRepository: AiModelCatalogRepository) =>
      new DeleteAiModelUseCase(aiModelCatalogRepository),
    inject: [AI_MODEL_CATALOG_REPOSITORY],
  },
  {
    provide: ADMIN_APPLICATION_TOKENS.getAdminLogFile,
    useFactory: (adminLogService: AdminLogService) =>
      new GetAdminLogFileUseCase(adminLogService),
    inject: [ADMIN_LOG_SERVICE],
  },
  {
    provide: ADMIN_APPLICATION_TOKENS.getAiModels,
    useFactory: (aiModelCatalogRepository: AiModelCatalogRepository) =>
      new GetAiModelsUseCase(aiModelCatalogRepository),
    inject: [AI_MODEL_CATALOG_REPOSITORY],
  },
  {
    provide: ADMIN_APPLICATION_TOKENS.getSystemConfig,
    useFactory: (systemConfigRepository: SystemConfigRepository) =>
      new GetSystemConfigUseCase(systemConfigRepository),
    inject: [SYSTEM_CONFIG_REPOSITORY],
  },
  {
    provide: ADMIN_APPLICATION_TOKENS.reorderAiModels,
    useFactory: (aiModelCatalogRepository: AiModelCatalogRepository) =>
      new ReorderAiModelsUseCase(aiModelCatalogRepository),
    inject: [AI_MODEL_CATALOG_REPOSITORY],
  },
  {
    provide: ADMIN_APPLICATION_TOKENS.saveAdminLog,
    useFactory: (adminLogService: AdminLogService) =>
      new SaveAdminLogUseCase(adminLogService),
    inject: [ADMIN_LOG_SERVICE],
  },
  {
    provide: ADMIN_APPLICATION_TOKENS.updateAiModel,
    useFactory: (aiModelCatalogRepository: AiModelCatalogRepository) =>
      new UpdateAiModelUseCase(aiModelCatalogRepository),
    inject: [AI_MODEL_CATALOG_REPOSITORY],
  },
  {
    provide: ADMIN_APPLICATION_TOKENS.updateSystemConfig,
    useFactory: (systemConfigRepository: SystemConfigRepository) =>
      new UpdateSystemConfigUseCase(systemConfigRepository),
    inject: [SYSTEM_CONFIG_REPOSITORY],
  },
];

export const adminUseCases = [
  ADMIN_APPLICATION_TOKENS.banUser,
  ADMIN_APPLICATION_TOKENS.listUsers,
  ADMIN_APPLICATION_TOKENS.login,
  ADMIN_APPLICATION_TOKENS.testAiChat,
  ADMIN_APPLICATION_TOKENS.createAiModel,
  ADMIN_APPLICATION_TOKENS.deleteAiModel,
  ADMIN_APPLICATION_TOKENS.getAdminLogFile,
  ADMIN_APPLICATION_TOKENS.getAiModels,
  ADMIN_APPLICATION_TOKENS.getSystemConfig,
  ADMIN_APPLICATION_TOKENS.reorderAiModels,
  ADMIN_APPLICATION_TOKENS.saveAdminLog,
  ADMIN_APPLICATION_TOKENS.updateAiModel,
  ADMIN_APPLICATION_TOKENS.updateSystemConfig,
];

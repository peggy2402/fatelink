import {
  AI_PROVIDER,
  type IAiProvider,
} from '@shared/contracts/ai-provider.service';
import { CreateAiMessageUseCase } from '@contexts/chat/application/usecases/create-ai-message.usecase';
import { CreateDirectChatMessageUseCase } from '@contexts/chat/application/usecases/create-direct-chat-message.usecase';
import { GetAiChatHistoryUseCase } from '@contexts/chat/application/usecases/get-ai-chat-history.usecase';
import { HandleRealtimeChatMessageOrchestrator } from '@contexts/chat/application/services/handle-realtime-chat-message.orchestrator';
import { HandleRealtimeChatMessageUseCase } from '@contexts/chat/application/usecases/handle-realtime-chat-message.usecase';
import { SendAiMessageUseCase } from '@contexts/chat/application/usecases/send-ai-message.usecase';
import type {
  CreateAiMessageHandler,
  GetAiChatHistoryHandler,
  SendAiMessageHandler,
} from '@contexts/chat/application/contracts/chat.handlers';
import type { UpdateUserTraitsHandler } from '@contexts/users/application/contracts/update-user-traits.contract';
import { USERS_APPLICATION_TOKENS } from '@contexts/users/composition/users.tokens';
import { CHAT_APPLICATION_TOKENS } from './chat.tokens';
import {
  AI_MODEL_CATALOG_REPOSITORY,
  CHAT_MESSAGE_REPOSITORY,
  SYSTEM_CONFIG_REPOSITORY,
} from '@shared/kernel/injection-tokens';
import type { AiModelCatalogRepository } from '@contexts/admin/domain/repositories/ai-model-catalog.repository';
import type { ChatMessageRepository } from '@contexts/chat/domain/repositories/chat-message.repository';
import type { SystemConfigRepository } from '@contexts/admin/domain/repositories/system-config.repository';
import type { Provider } from '@nestjs/common';

export const chatUseCaseProviders: Provider[] = [
  {
    provide: CHAT_APPLICATION_TOKENS.createMessage,
    useFactory: (chatMessageRepository: ChatMessageRepository) =>
      new CreateAiMessageUseCase(chatMessageRepository),
    inject: [CHAT_MESSAGE_REPOSITORY],
  },
  {
    provide: CHAT_APPLICATION_TOKENS.createDirectMessage,
    useFactory: (chatMessageRepository: ChatMessageRepository) =>
      new CreateDirectChatMessageUseCase(chatMessageRepository),
    inject: [CHAT_MESSAGE_REPOSITORY],
  },
  {
    provide: CHAT_APPLICATION_TOKENS.getHistory,
    useFactory: (chatMessageRepository: ChatMessageRepository) =>
      new GetAiChatHistoryUseCase(chatMessageRepository),
    inject: [CHAT_MESSAGE_REPOSITORY],
  },
  {
    provide: CHAT_APPLICATION_TOKENS.sendAiMessage,
    useFactory: (
      providers: IAiProvider[],
      aiModelCatalogRepository: AiModelCatalogRepository,
      systemConfigRepository: SystemConfigRepository,
    ) =>
      new SendAiMessageUseCase(
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
    provide: CHAT_APPLICATION_TOKENS.handleRealtimeMessage,
    useFactory: (
      createAiMessageHandler: CreateAiMessageHandler,
      getAiChatHistoryHandler: GetAiChatHistoryHandler,
      sendAiMessageHandler: SendAiMessageHandler,
      updateUserTraitsHandler: UpdateUserTraitsHandler,
    ) =>
      new HandleRealtimeChatMessageUseCase(
        new HandleRealtimeChatMessageOrchestrator(
          createAiMessageHandler,
          getAiChatHistoryHandler,
          sendAiMessageHandler,
          updateUserTraitsHandler,
        ),
      ),
    inject: [
      CHAT_APPLICATION_TOKENS.createMessage,
      CHAT_APPLICATION_TOKENS.getHistory,
      CHAT_APPLICATION_TOKENS.sendAiMessage,
      USERS_APPLICATION_TOKENS.updateUserTraits,
    ],
  },
];

export const chatUseCases = [
  CHAT_APPLICATION_TOKENS.createMessage,
  CHAT_APPLICATION_TOKENS.createDirectMessage,
  CHAT_APPLICATION_TOKENS.getHistory,
  CHAT_APPLICATION_TOKENS.sendAiMessage,
  CHAT_APPLICATION_TOKENS.handleRealtimeMessage,
];

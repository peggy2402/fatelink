import type {
  ChatHistoryItem,
  LoadChatHistoryQuery,
  PersistChatMessageCommand,
  SendChatMessageCommand,
} from '@contexts/chat/application/contracts/chat.commands';
import type { Message } from '@contexts/chat/domain/entities/message';

export interface CreateAiMessageHandler {
  execute(input: PersistChatMessageCommand): Promise<Message> | Message;
}

export interface GetAiChatHistoryHandler {
  execute(
    input: LoadChatHistoryQuery,
  ): Promise<Array<ChatHistoryItem & { timestamp?: Date | string }>>;
}

export interface SendAiMessageHandler {
  execute(input: SendChatMessageCommand): Promise<string>;
}

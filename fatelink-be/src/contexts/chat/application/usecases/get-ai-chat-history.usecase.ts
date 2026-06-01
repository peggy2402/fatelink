import type { LoadChatHistoryQuery } from '@contexts/chat/application/contracts/chat.commands';
import type { GetAiChatHistoryHandler } from '@contexts/chat/application/contracts/chat.handlers';
import type { ChatMessageRepository } from '@contexts/chat/domain/repositories/chat-message.repository';

export class GetAiChatHistoryUseCase implements GetAiChatHistoryHandler {
  constructor(private readonly chatMessageRepository: ChatMessageRepository) {}

  async execute(input: LoadChatHistoryQuery) {
    const messages = await this.chatMessageRepository.getAiHistoryForUser(
      input.userId,
      input.limit || 30,
    );

    return messages.reverse().map((msg) => ({
      text: msg.text,
      isSentByMe: msg.isSentByMe,
      timestamp: msg.createdAt,
    }));
  }
}

import type { PersistChatMessageCommand } from '@contexts/chat/application/contracts/chat.commands';
import type { CreateAiMessageHandler } from '@contexts/chat/application/contracts/chat.handlers';
import type { ChatMessageRepository } from '@contexts/chat/domain/repositories/chat-message.repository';

export class CreateAiMessageUseCase implements CreateAiMessageHandler {
  constructor(private readonly chatMessageRepository: ChatMessageRepository) {}

  execute(input: PersistChatMessageCommand) {
    return this.chatMessageRepository.createAiMessage(
      input.userId,
      input.text,
      input.isSentByMe,
    );
  }
}

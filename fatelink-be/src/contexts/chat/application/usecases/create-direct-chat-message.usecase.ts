import type { ChatMessageRepository } from '@contexts/chat/domain/repositories/chat-message.repository';

export class CreateDirectChatMessageUseCase {
  constructor(private readonly chatMessageRepository: ChatMessageRepository) {}

  execute(input: { senderId: string; partnerId: string; text: string }) {
    return this.chatMessageRepository.createDirectMessage(
      input.senderId,
      input.partnerId,
      input.text,
    );
  }
}

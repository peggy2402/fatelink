import type { ChatMessageRepository } from '@contexts/chat/domain/repositories/chat-message.repository';

export class GetDirectChatHistoryUseCase {
  constructor(private readonly chatMessageRepository: ChatMessageRepository) {}

  async execute(input: { userId: string; partnerId: string; limit?: number }) {
    const conversationId = [input.userId, input.partnerId].sort().join(':');
    const messages =
      await this.chatMessageRepository.getDirectHistoryForConversation(
        input.userId,
        conversationId,
        input.limit || 50,
      );

    return messages.reverse().map((msg) => ({
      text: msg.text,
      isSentByMe: msg.isSentByMe,
      timestamp: (msg.createdAt ?? new Date()).toISOString(),
    }));
  }
}

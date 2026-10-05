import type {
  ChatMessageRepository,
  RecentConversationItem,
} from '@contexts/chat/domain/repositories/chat-message.repository';

export class GetRecentConversationsUseCase {
  constructor(private readonly chatMessageRepository: ChatMessageRepository) {}

  async execute(input: { userId: string }): Promise<RecentConversationItem[]> {
    return this.chatMessageRepository.getRecentConversations(input.userId);
  }
}

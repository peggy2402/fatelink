import { type Message } from '@contexts/chat/domain/entities/message';

export interface ChatMessageRepository {
  createAiMessage(
    userId: string,
    text: string,
    isSentByMe: boolean,
  ): Promise<Message>;
  createDirectMessage(
    senderId: string,
    partnerId: string,
    text: string,
  ): Promise<Message>;
  getAiHistoryForUser(userId: string, limit: number): Promise<Message[]>;
  getDirectHistoryForConversation(
    viewerUserId: string,
    conversationId: string,
    limit: number,
  ): Promise<Message[]>;
}

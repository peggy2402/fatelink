import { type Message } from '@contexts/chat/domain/entities/message';

export interface RecentConversationItem {
  partnerId: string;
  lastMessage: string;
  lastMessageTime: Date;
  isSentByMe: boolean;
  unreadCount?: number;
}

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
    options?: {
      messageType?: string;
      mediaUrl?: string;
      durationMs?: number;
      waveform?: number[];
      imageUrls?: string[];
      clientMessageId?: string;
    },
  ): Promise<Message>;
  getAiHistoryForUser(userId: string, limit: number): Promise<Message[]>;
  getDirectHistoryForConversation(
    viewerUserId: string,
    conversationId: string,
    limit: number,
  ): Promise<Message[]>;
  getRecentConversations(userId: string): Promise<RecentConversationItem[]>;
}

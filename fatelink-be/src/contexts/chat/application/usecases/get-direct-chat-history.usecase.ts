import type { ChatMessageRepository } from '@contexts/chat/domain/repositories/chat-message.repository';

export class GetDirectChatHistoryUseCase {
  constructor(private readonly chatMessageRepository: ChatMessageRepository) {}

  async execute(input: {
    userId: string;
    partnerId: string;
    limit?: number;
    after?: string;
  }) {
    const conversationId = [input.userId, input.partnerId].sort().join(':');
    const messages =
      await this.chatMessageRepository.getDirectHistoryForConversation(
        input.userId,
        conversationId,
        input.limit || 50,
        input.after,
      );

    return messages.reverse().map((msg) => {
      let messageType = msg.messageType || 'text';
      const mediaUrl = msg.mediaUrl;
      const durationMs = msg.durationMs;
      const waveform = msg.waveform;
      const imageUrls = msg.imageUrls;

      // Tương thích ngược: Phục hồi định dạng cho các tin nhắn cũ chưa có messageType riêng
      if (messageType === 'text') {
        if (mediaUrl) {
          messageType = 'voice';
        } else if (imageUrls && imageUrls.length > 0) {
          messageType = 'image';
        } else if (
          msg.text?.startsWith('[Ghi âm]') ||
          msg.text?.startsWith('[Tin nhắn thoại]')
        ) {
          messageType = 'voice';
        } else if (msg.text?.startsWith('[Hình ảnh]')) {
          messageType = 'image';
        }
      }

      return {
        id: msg.id,
        text: msg.text,
        isSentByMe: msg.isSentByMe,
        timestamp: (msg.createdAt ?? new Date()).toISOString(),
        messageType,
        mediaUrl: mediaUrl || null,
        durationMs: durationMs || null,
        waveform: waveform && waveform.length > 0 ? waveform : null,
        imageUrls: imageUrls && imageUrls.length > 0 ? imageUrls : null,
        clientMessageId: msg.clientMessageId || null,
      };
    });
  }
}

import type { ChatMessageRepository } from '@contexts/chat/domain/repositories/chat-message.repository';

export class CreateDirectChatMessageUseCase {
  constructor(private readonly chatMessageRepository: ChatMessageRepository) {}

  execute(input: {
    senderId: string;
    partnerId: string;
    text: string;
    messageType?: string;
    mediaUrl?: string;
    durationMs?: number;
    waveform?: number[];
    imageUrls?: string[];
    clientMessageId?: string;
  }) {
    return this.chatMessageRepository.createDirectMessage(
      input.senderId,
      input.partnerId,
      input.text,
      {
        messageType: input.messageType,
        mediaUrl: input.mediaUrl,
        durationMs: input.durationMs,
        waveform: input.waveform,
        imageUrls: input.imageUrls,
        clientMessageId: input.clientMessageId,
      },
    );
  }
}

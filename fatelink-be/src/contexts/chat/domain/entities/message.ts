export class Message {
  id?: string;
  userId!: string;
  partnerId?: string;
  text!: string;
  isSentByMe!: boolean;
  conversationType!: 'ai' | 'direct';
  conversationId?: string;
  senderId?: string;
  recipientId?: string;
  messageType?: string;
  mediaUrl?: string;
  durationMs?: number;
  waveform?: number[];
  imageUrls?: string[];
  clientMessageId?: string;
  createdAt?: Date;
  updatedAt?: Date;
}

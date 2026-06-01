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
  createdAt?: Date;
  updatedAt?: Date;
}

import type { ChatMessageRepository as ChatMessageRepositoryPort } from '@contexts/chat/domain/repositories/chat-message.repository';
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Message } from '../models/message.model';

@Injectable()
export class MongooseChatMessageRepository implements ChatMessageRepositoryPort {
  constructor(
    @InjectModel(Message.name) private readonly messageModel: Model<Message>,
  ) {}

  async createAiMessage(
    userId: string,
    text: string,
    isSentByMe: boolean,
  ): Promise<Message> {
    const message = new this.messageModel({
      userId,
      text,
      isSentByMe,
      conversationType: 'ai',
      isDirect: false,
    });
    return message.save();
  }

  async createDirectMessage(
    senderId: string,
    partnerId: string,
    text: string,
  ): Promise<Message> {
    const conversationId = this.getDirectConversationId(senderId, partnerId);
    const senderMessage = new this.messageModel({
      userId: senderId,
      partnerId,
      conversationType: 'direct',
      conversationId,
      senderId,
      recipientId: partnerId,
      text,
      isSentByMe: true,
      isDirect: true,
    });
    const recipientMessage = new this.messageModel({
      userId: partnerId,
      partnerId: senderId,
      conversationType: 'direct',
      conversationId,
      senderId,
      recipientId: partnerId,
      text,
      isSentByMe: false,
      isDirect: true,
    });

    await recipientMessage.save();
    return senderMessage.save();
  }

  async getAiHistoryForUser(userId: string, limit: number): Promise<Message[]> {
    return this.messageModel
      .find({
        userId,
        $or: [
          { conversationType: 'ai' },
          { conversationType: { $exists: false }, isDirect: { $ne: true } },
        ],
      })
      .sort({ createdAt: -1 })
      .limit(limit)
      .exec();
  }

  async getDirectHistoryForConversation(
    viewerUserId: string,
    conversationId: string,
    limit: number,
  ): Promise<Message[]> {
    return this.messageModel
      .find({
        userId: viewerUserId,
        conversationType: 'direct',
        conversationId,
      })
      .sort({ createdAt: -1 })
      .limit(limit)
      .exec();
  }

  private getDirectConversationId(firstUserId: string, secondUserId: string) {
    return [firstUserId, secondUserId].sort().join(':');
  }
}

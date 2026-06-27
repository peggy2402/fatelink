import type { ChatMessageRepository as ChatMessageRepositoryPort } from '@contexts/chat/domain/repositories/chat-message.repository';
import { Message as DomainMessage } from '@contexts/chat/domain/entities/message';
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import type { HydratedDocument, Model } from 'mongoose';
import { Message, type MessageDocument } from '../models/message.model';

@Injectable()
export class MongooseChatMessageRepository implements ChatMessageRepositoryPort {
  constructor(
    @InjectModel(Message.name)
    private readonly messageModel: Model<MessageDocument>,
  ) {}

  async createAiMessage(
    userId: string,
    text: string,
    isSentByMe: boolean,
  ): Promise<DomainMessage> {
    const message = new this.messageModel({
      userId,
      text,
      isSentByMe,
      conversationType: 'ai',
      isDirect: false,
    });
    return this.toDomainMessage(await message.save());
  }

  async createDirectMessage(
    senderId: string,
    partnerId: string,
    text: string,
  ): Promise<DomainMessage> {
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
    return this.toDomainMessage(await senderMessage.save());
  }

  async getAiHistoryForUser(
    userId: string,
    limit: number,
  ): Promise<DomainMessage[]> {
    const messages = await this.messageModel
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
    return messages.map((message) => this.toDomainMessage(message));
  }

  async getDirectHistoryForConversation(
    viewerUserId: string,
    conversationId: string,
    limit: number,
  ): Promise<DomainMessage[]> {
    const messages = await this.messageModel
      .find({
        userId: viewerUserId,
        conversationType: 'direct',
        conversationId,
      })
      .sort({ createdAt: -1 })
      .limit(limit)
      .exec();
    return messages.map((message) => this.toDomainMessage(message));
  }

  private getDirectConversationId(firstUserId: string, secondUserId: string) {
    return [firstUserId, secondUserId].sort().join(':');
  }

  private toDomainMessage(document: HydratedDocument<Message>): DomainMessage {
    const plainMessage = document.toObject();

    const message = new DomainMessage();
    message.id = document._id.toString();
    message.userId = plainMessage.userId;
    message.partnerId = plainMessage.partnerId;
    message.text = plainMessage.text;
    message.isSentByMe = plainMessage.isSentByMe;
    message.conversationType = plainMessage.conversationType;
    message.conversationId = plainMessage.conversationId;
    message.senderId = plainMessage.senderId;
    message.recipientId = plainMessage.recipientId;
    message.createdAt = plainMessage.createdAt;
    message.updatedAt = plainMessage.updatedAt;
    return message;
  }
}

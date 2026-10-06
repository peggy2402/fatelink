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
    options?: {
      messageType?: string;
      mediaUrl?: string;
      durationMs?: number;
      waveform?: number[];
      imageUrls?: string[];
      clientMessageId?: string;
    },
  ): Promise<DomainMessage> {
    const conversationId = this.getDirectConversationId(senderId, partnerId);

    // 1. Kiểm tra Idempotency: Nếu tin nhắn đã có clientMessageId từ sender này, trả về tin cũ
    if (options?.clientMessageId) {
      const existing = await this.messageModel.findOne({
        senderId,
        clientMessageId: options.clientMessageId,
      });
      if (existing) {
        return this.toDomainMessage(existing);
      }
    }

    const messageType = options?.messageType || 'text';
    const mediaUrl = options?.mediaUrl;
    const durationMs = options?.durationMs;
    const waveform = options?.waveform;
    const imageUrls = options?.imageUrls;
    const clientMessageId = options?.clientMessageId;

    try {
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
        messageType,
        mediaUrl,
        durationMs,
        waveform,
        imageUrls,
        clientMessageId,
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
        messageType,
        mediaUrl,
        durationMs,
        waveform,
        imageUrls,
      });

      await recipientMessage.save();
      return this.toDomainMessage(await senderMessage.save());
    } catch (error: any) {
      // Bắt lỗi trùng khóa unique (E11000) nếu hai request đến cùng mili-giây
      if (error?.code === 11000 && clientMessageId) {
        const existing = await this.messageModel.findOne({
          senderId,
          clientMessageId,
        });
        if (existing) {
          return this.toDomainMessage(existing);
        }
      }
      throw error;
    }
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

  async getRecentConversations(userId: string) {
    const results = await this.messageModel.aggregate([
      {
        $match: {
          userId,
          conversationType: 'direct',
        },
      },
      {
        $sort: { createdAt: -1 },
      },
      {
        $group: {
          _id: '$partnerId',
          partnerId: { $first: '$partnerId' },
          lastMessage: { $first: '$text' },
          lastMessageTime: { $first: '$createdAt' },
          isSentByMe: { $first: '$isSentByMe' },
        },
      },
      {
        $sort: { lastMessageTime: -1 },
      },
    ]);

    return results.map((item) => ({
      partnerId: item.partnerId || item._id,
      lastMessage: item.lastMessage || '',
      lastMessageTime: item.lastMessageTime || new Date(),
      isSentByMe: !!item.isSentByMe,
      unreadCount: 0,
    }));
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
    message.messageType = plainMessage.messageType || 'text';
    message.mediaUrl = plainMessage.mediaUrl;
    message.durationMs = plainMessage.durationMs;
    message.waveform = plainMessage.waveform;
    message.imageUrls = plainMessage.imageUrls;
    message.clientMessageId = plainMessage.clientMessageId;
    message.createdAt = plainMessage.createdAt;
    message.updatedAt = plainMessage.updatedAt;
    return message;
  }
}

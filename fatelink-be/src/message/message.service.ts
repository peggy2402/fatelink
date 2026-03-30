import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Message } from './schemas/message.schema';

@Injectable()
export class MessageService {
  constructor(
    @InjectModel(Message.name)
    private readonly messageModel: Model<Message>,
  ) {}

  async createMessage(userId: string, text: string, isSentByMe: boolean) {
    const message = new this.messageModel({
      userId,
      text,
      isSentByMe,
    });
    return message.save();
  }

  async getHistoryForUser(userId: string, limit: number = 30) {
    const messages = await this.messageModel
      .find({ userId })
      .sort({ createdAt: -1 }) // Lấy tin nhắn mới nhất
      .limit(limit)
      .exec();
      
    // Đảo ngược mảng và map về chuẩn { text, isSentByMe, timestamp } cho Flutter
    return messages.reverse().map(msg => ({
      text: msg.text,
      isSentByMe: msg.isSentByMe,
      timestamp: (msg as any).createdAt,
    }));
  }
}
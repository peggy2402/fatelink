import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true }) // Tự động tạo trường createdAt và updatedAt
export class Message extends Document {
  @Prop({ required: true })
  userId: string;

  @Prop({ required: true })
  text: string;

  @Prop({ required: true })
  isSentByMe: boolean;
}

export const MessageSchema = SchemaFactory.createForClass(Message);
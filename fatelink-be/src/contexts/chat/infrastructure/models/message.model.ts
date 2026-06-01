import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class Message extends Document {
  @Prop({ required: true })
  userId!: string;

  @Prop()
  partnerId?: string;

  @Prop({ required: true, enum: ['ai', 'direct'], default: 'ai', index: true })
  conversationType!: 'ai' | 'direct';

  @Prop({ index: true })
  conversationId?: string;

  @Prop()
  senderId?: string;

  @Prop()
  recipientId?: string;

  @Prop({ required: true })
  text!: string;

  @Prop({ required: true })
  isSentByMe!: boolean;

  @Prop({ default: false })
  isDirect!: boolean;
}

export const MessageSchema = SchemaFactory.createForClass(Message);

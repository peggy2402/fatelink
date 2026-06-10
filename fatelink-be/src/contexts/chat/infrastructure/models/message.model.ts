import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type MessageDocument = HydratedDocument<Message>;

@Schema({ timestamps: true })
export class Message {
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

  createdAt!: Date;
  updatedAt!: Date;
}

export const MessageSchema = SchemaFactory.createForClass(Message);

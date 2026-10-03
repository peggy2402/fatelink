import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type NotificationDocument = HydratedDocument<Notification>;

@Schema({ timestamps: true })
export class Notification {
  @Prop({ required: true, index: true })
  userId!: string; // Người nhận thông báo

  @Prop({ required: true })
  senderId!: string; // Người tương tác (xem profile, thả tim, gửi sóng)

  @Prop({ default: 'Linh hồn bí ẩn' })
  senderName!: string;

  @Prop({ default: '' })
  senderAvatar!: string;

  @Prop({
    required: true,
    enum: ['view_profile', 'like', 'mutual_match', 'wave', 'system'],
  })
  type!: string;

  @Prop({ required: true })
  title!: string;

  @Prop({ required: true })
  message!: string;

  @Prop({ default: false })
  isRead!: boolean;

  createdAt?: Date;
  updatedAt?: Date;
}

export const NotificationSchema = SchemaFactory.createForClass(Notification);

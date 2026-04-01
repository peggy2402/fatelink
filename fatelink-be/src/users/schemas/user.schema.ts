import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type UserDocument = HydratedDocument<User>;

@Schema({ _id: false })
export class EmotionVector {
  @Prop({ default: 5 }) stress: number;
  @Prop({ default: 5 }) loneliness: number;
  @Prop({ default: 5 }) sadness: number;
  @Prop({ default: 5 }) calmness: number;
  @Prop({ default: 5 }) warmth: number;
  @Prop({ default: 5 }) happiness: number;
}

@Schema({ timestamps: true }) // Tự động tạo createdAt, updatedAt
export class User {
  @Prop({ required: true, unique: true })
  email: string;

  @Prop()
  name: string;

  @Prop()
  avatar: string;

  @Prop({ unique: true, sparse: true })
  googleId: string;

  @Prop({ default: 'Bí ẩn' })
  latestEmotion: string; // Trạng thái cảm xúc chủ đạo (Ví dụ: Bình yên, Cô đơn...)

  @Prop({ type: EmotionVector, default: () => ({}) })
  emotions: EmotionVector; // Vector cảm xúc chi tiết (0-10)

  @Prop({ type: [Number], default: [5, 5, 5] })
  personality: number[]; // Vector tính cách [Hướng ngoại, Cảm xúc, Nhanh nhẹn]

  @Prop({ default: 'Đang tìm kiếm một kết nối định mệnh...' })
  bio: string;
}

export const UserSchema = SchemaFactory.createForClass(User);
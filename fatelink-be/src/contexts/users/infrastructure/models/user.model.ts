import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type UserDocument = HydratedDocument<User>;

@Schema({ _id: false })
export class EmotionVector {
  @Prop({ default: 5 }) stress!: number;
  @Prop({ default: 5 }) loneliness!: number;
  @Prop({ default: 5 }) sadness!: number;
  @Prop({ default: 5 }) calmness!: number;
  @Prop({ default: 5 }) warmth!: number;
  @Prop({ default: 5 }) happiness!: number;
}

@Schema({ timestamps: true })
export class User {
  @Prop({ unique: true, sparse: true })
  email?: string;

  @Prop()
  name!: string;

  @Prop()
  avatar!: string;

  @Prop({ default: 'Bí ẩn' })
  latestEmotion!: string;

  @Prop({ type: EmotionVector, default: () => ({}) })
  emotions!: EmotionVector;

  @Prop({ type: [Number], default: [5, 5, 5] })
  personality!: number[];

  @Prop({ default: 'Đang tìm kiếm một kết nối định mệnh...' })
  bio!: string;

  @Prop({ default: '' })
  fcmToken!: string;
}

export const UserSchema = SchemaFactory.createForClass(User);

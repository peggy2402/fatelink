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

@Schema({ _id: false })
export class VibePhoto {
  @Prop({ required: true })
  id!: string;

  @Prop({ required: true })
  imageUrl!: string;

  @Prop({ default: () => new Date() })
  createdAt!: Date;

  @Prop({ default: 1440 })
  durationMinutes!: number;

  @Prop({ required: true })
  expiresAt!: Date;
}

@Schema({ timestamps: true })
export class User {
  @Prop({ unique: true, sparse: true })
  email?: string;

  @Prop({ unique: true, sparse: true })
  handle?: string;

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

  @Prop({ default: 'Đang tìm kiếm một kết nối định mệnh...', maxlength: 100 })
  bio!: string;

  @Prop({ default: 'female' })
  gender!: string;

  @Prop({ default: '' })
  dateOfBirth!: string;

  @Prop({ default: '' })
  address!: string;

  @Prop({ default: false })
  isFaceLocked!: boolean;

  @Prop({ type: [VibePhoto], default: () => [] })
  vibePhotos!: VibePhoto[];

  @Prop({ default: '' })
  fcmToken!: string;

  @Prop({ type: [String], default: () => [] })
  tags!: string[];

  @Prop({ default: '528 Hz' })
  frequencyHertz!: string;

  @Prop({ default: '🌧️' })
  moodIcon!: string;

  @Prop({ default: '' })
  desiredVibe!: string;
}

export const UserSchema = SchemaFactory.createForClass(User);

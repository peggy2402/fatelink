import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type UserDocument = HydratedDocument<User>;

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

  @Prop({ default: 'Bình thường' })
  detected_emotion: string; // Lưu trạng thái cảm xúc gần nhất do AI phân tích
}

export const UserSchema = SchemaFactory.createForClass(User);
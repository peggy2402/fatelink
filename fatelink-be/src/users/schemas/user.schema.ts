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

  @Prop({ type: [String], default: [] })
  emotionalStates: string[]; // Mảng linh hoạt để AI lưu các tags cảm xúc
}

export const UserSchema = SchemaFactory.createForClass(User);
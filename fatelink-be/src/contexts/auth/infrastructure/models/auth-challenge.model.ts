import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type AuthChallengeDocument = HydratedDocument<AuthChallenge>;

@Schema({ timestamps: true })
export class AuthChallenge {
  @Prop({ required: true, enum: ['phone_otp', 'magic_link'] })
  type!: 'phone_otp' | 'magic_link';

  @Prop({ required: true })
  key!: string;

  @Prop({ required: true })
  secretHash!: string;

  @Prop({ required: true })
  expiresAt!: Date;

  @Prop({ default: 0 })
  attemptCount!: number;

  @Prop({ default: 5 })
  maxAttempts!: number;

  @Prop()
  lockedAt?: Date;

  @Prop({ type: Object, default: {} })
  metadata?: Record<string, string>;
}

export const AuthChallengeSchema = SchemaFactory.createForClass(AuthChallenge);
AuthChallengeSchema.index({ type: 1, key: 1 }, { unique: true });

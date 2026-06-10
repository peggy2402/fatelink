import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type AuthIdentityDocument = HydratedDocument<AuthIdentity>;

@Schema({ timestamps: true })
export class AuthIdentity {
  @Prop({ required: true })
  userId!: string;

  @Prop({ required: true, enum: ['email', 'facebook', 'phone', 'google'] })
  provider!: 'email' | 'facebook' | 'phone' | 'google';

  @Prop({ required: true })
  providerUserId!: string;

  @Prop()
  providerEmail?: string;

  @Prop()
  secretHash?: string;
}

export const AuthIdentitySchema = SchemaFactory.createForClass(AuthIdentity);
AuthIdentitySchema.index({ provider: 1, providerUserId: 1 }, { unique: true });

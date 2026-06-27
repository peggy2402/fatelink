import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import {
  AUTH_SESSION_STATUS,
  type AuthSessionStatus,
} from '@contexts/auth/domain/repositories/auth-session.repository';
import { HydratedDocument } from 'mongoose';

export type AuthSessionDocument = HydratedDocument<AuthSession>;

@Schema({ timestamps: true })
export class AuthSession {
  @Prop({ required: true, unique: true })
  sessionId!: string;

  @Prop({ required: true })
  userId!: string;

  @Prop({ required: true })
  deviceType!: string;

  @Prop({ required: true })
  deviceId!: string;

  @Prop({ required: true, unique: true })
  refreshTokenHash!: string;

  @Prop({
    type: String,
    required: true,
    enum: Object.values(AUTH_SESSION_STATUS),
    default: AUTH_SESSION_STATUS.ACTIVE,
  })
  status!: AuthSessionStatus;

  @Prop()
  ipAddress?: string;

  @Prop()
  userAgent?: string;

  @Prop({ required: true })
  lastRefreshedAt!: Date;

  @Prop({ required: true })
  lastSeenAt!: Date;

  @Prop()
  revokedAt?: Date;

  @Prop()
  revokedReason?: string;

  @Prop()
  replacedBySessionId?: string;

  createdAt!: Date;
  updatedAt!: Date;
}

export const AuthSessionSchema = SchemaFactory.createForClass(AuthSession);
AuthSessionSchema.index({ userId: 1, createdAt: -1 });
AuthSessionSchema.index({ userId: 1, status: 1, createdAt: -1 });
AuthSessionSchema.index({ userId: 1, deviceId: 1, status: 1 });

import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type SystemConfigDocument = SystemConfig & Document;

@Schema({ timestamps: true })
export class SystemConfig {
  @Prop({
    default:
      'Bạn là Faye - một AI thấu hiểu cảm xúc. Hãy trò chuyện ngắn gọn, tự nhiên và thân thiện...',
  })
  systemPrompt!: string;

  @Prop({ default: '' })
  additionalKnowledge!: string;

  @Prop({ default: 10 })
  onboardingMessageLimit!: number;
}

export const SystemConfigSchema = SchemaFactory.createForClass(SystemConfig);

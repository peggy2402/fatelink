import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type SystemConfigDocument = SystemConfig & Document;

@Schema({ timestamps: true })
export class SystemConfig {
  @Prop({ default: 'gemini' }) // 'gemini', 'openai', 'llama'
  activeAiProvider: string;

  @Prop({ default: 'gemini-2.0-flash' })
  geminiModel: string;

  @Prop({ default: 'llama-3.1-8b-instant' })
  groqModel: string;

  @Prop({ 
    default: 'Bạn là Faye - một AI thấu hiểu cảm xúc. Hãy trò chuyện ngắn gọn, tự nhiên và thân thiện...' 
  })
  systemPrompt: string;
  
  @Prop({ default: 10 }) // Số tin nhắn tối đa trong luồng Onboarding
  onboardingMessageLimit: number;
}

export const SystemConfigSchema = SchemaFactory.createForClass(SystemConfig);
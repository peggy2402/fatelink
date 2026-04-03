import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type AiModelDocument = AiModel & Document;

@Schema({ timestamps: true })
export class AiModel {
  @Prop({ required: true, unique: true })
  modelId!: string; // Ví dụ: 'Qwen/Qwen2.5-7B-Instruct' hoặc 'gemini-2.0-flash'

  @Prop({ required: true })
  providerName!: string; // Ví dụ: 'HuggingFace', 'Gemini', 'OpenAI'

  @Prop({ required: true })
  displayName!: string; // Tên hiển thị trên UI: 'Qwen 2.5 7B (Tiếng Việt tốt)'

  @Prop({ default: true })
  isEnabled!: boolean; // Cho phép bật/tắt model

  @Prop({ default: 0 })
  priority!: number; // Độ ưu tiên (số nhỏ hơn được ưu tiên cao hơn)
}

export const AiModelSchema = SchemaFactory.createForClass(AiModel);
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type AiModelDocument = AiModel & Document;

@Schema({ timestamps: true })
export class AiModel {
  @Prop({ required: true, unique: true })
  modelId!: string;

  @Prop({ required: true })
  providerName!: string;

  @Prop({ required: true })
  displayName!: string;

  @Prop({ default: true })
  isEnabled!: boolean;

  @Prop({ default: 0 })
  priority!: number;
}

export const AiModelSchema = SchemaFactory.createForClass(AiModel);

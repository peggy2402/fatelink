import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type ReportDocument = HydratedDocument<Report>;

@Schema({ timestamps: true })
export class Report {
  @Prop({ required: true })
  reporterId!: string;

  @Prop({ required: true })
  targetUserId!: string;

  @Prop({ required: true })
  reason!: string;

  @Prop({ default: '' })
  details!: string;

  @Prop({ default: 'pending' })
  status!: string;
}

export const ReportSchema = SchemaFactory.createForClass(Report);

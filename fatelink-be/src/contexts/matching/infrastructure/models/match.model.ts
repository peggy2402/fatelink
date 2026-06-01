import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type MatchDocument = Match & Document;

@Schema({ timestamps: true })
export class Match {
  @Prop({ required: true })
  user1!: string;

  @Prop({ required: true })
  user2!: string;
}

export const MatchSchema = SchemaFactory.createForClass(Match);

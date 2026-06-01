import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type MatchCandidateReadDocument =
  HydratedDocument<MatchCandidateReadModel>;

@Schema({ _id: false })
export class MatchCandidateReadEmotionVector {
  @Prop({ default: 5 }) stress!: number;
  @Prop({ default: 5 }) loneliness!: number;
  @Prop({ default: 5 }) sadness!: number;
  @Prop({ default: 5 }) calmness!: number;
  @Prop({ default: 5 }) warmth!: number;
  @Prop({ default: 5 }) happiness!: number;
}

@Schema({ collection: 'users', strict: false })
export class MatchCandidateReadModel {
  @Prop()
  name!: string;

  @Prop()
  latestEmotion!: string;

  @Prop({ type: MatchCandidateReadEmotionVector, default: () => ({}) })
  emotions!: MatchCandidateReadEmotionVector;

  @Prop({ type: [Number], default: [5, 5, 5] })
  personality!: number[];

  @Prop()
  bio!: string;
}

export const MatchCandidateReadSchema = SchemaFactory.createForClass(
  MatchCandidateReadModel,
);

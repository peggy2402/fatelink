import type {
  MatchCandidate,
  MatchCandidateRepository,
} from '@contexts/matching/domain/repositories/match-candidate.repository';
import {
  MatchCandidateReadModel,
  type MatchCandidateReadDocument,
} from '@contexts/matching/infrastructure/models/match-candidate-read.model';
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import type { HydratedDocument, Model } from 'mongoose';

@Injectable()
export class MongooseMatchCandidateRepository implements MatchCandidateRepository {
  constructor(
    @InjectModel(MatchCandidateReadModel.name)
    private readonly userModel: Model<MatchCandidateReadDocument>,
  ) {}

  async findCurrentUser(userId: string): Promise<MatchCandidate | null> {
    const user = await this.userModel.findById(userId).exec();
    return user ? this.toCandidate(user) : null;
  }

  async findOtherCandidates(userId: string): Promise<MatchCandidate[]> {
    const users = await this.userModel.find({ _id: { $ne: userId } }).exec();
    return users.map((user) => this.toCandidate(user));
  }

  private toCandidate(
    document: HydratedDocument<MatchCandidateReadModel>,
  ): MatchCandidate {
    return {
      id: document._id.toString(),
      displayName: document.name || 'Nguoi Dau Ten',
      latestEmotion: document.latestEmotion || 'Bi an',
      bio: document.bio || 'Chua co tieu su',
      emotions: document.emotions
        ? {
            stress: document.emotions.stress,
            loneliness: document.emotions.loneliness,
            sadness: document.emotions.sadness,
            calmness: document.emotions.calmness,
            warmth: document.emotions.warmth,
            happiness: document.emotions.happiness,
          }
        : undefined,
      personality: Array.isArray(document.personality)
        ? [...document.personality]
        : undefined,
    };
  }
}

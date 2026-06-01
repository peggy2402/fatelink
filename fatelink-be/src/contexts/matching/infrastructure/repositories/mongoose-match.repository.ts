import type { MatchRepository as MatchRepositoryPort } from '@contexts/matching/domain/repositories/match.repository';
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Match, MatchDocument } from '../models/match.model';

@Injectable()
export class MongooseMatchRepository implements MatchRepositoryPort {
  constructor(
    @InjectModel(Match.name) private readonly matchModel: Model<MatchDocument>,
  ) {}

  async deleteMatchBetweenUsers(
    userId: string,
    partnerId: string,
  ): Promise<number> {
    const result = await this.matchModel.deleteOne({
      $or: [
        { user1: userId, user2: partnerId },
        { user1: partnerId, user2: userId },
      ],
    });

    return result.deletedCount ?? 0;
  }
}

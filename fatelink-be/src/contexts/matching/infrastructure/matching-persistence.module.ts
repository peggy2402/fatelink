import {
  MATCH_CANDIDATE_REPOSITORY,
  MATCH_REPOSITORY,
} from '@shared/kernel/injection-tokens';
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Match, MatchSchema } from './models/match.model';
import {
  MatchCandidateReadModel,
  MatchCandidateReadSchema,
} from './models/match-candidate-read.model';
import { MongooseMatchCandidateRepository } from './repositories/mongoose-match-candidate.repository';
import { MongooseMatchRepository } from './repositories/mongoose-match.repository';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Match.name, schema: MatchSchema },
      {
        name: MatchCandidateReadModel.name,
        schema: MatchCandidateReadSchema,
      },
    ]),
  ],
  providers: [
    {
      provide: MATCH_REPOSITORY,
      useClass: MongooseMatchRepository,
    },
    {
      provide: MATCH_CANDIDATE_REPOSITORY,
      useClass: MongooseMatchCandidateRepository,
    },
  ],
  exports: [MATCH_REPOSITORY, MATCH_CANDIDATE_REPOSITORY],
})
export class MatchingPersistenceModule {}

import {
  matchmakingUseCaseProviders,
  matchmakingUseCases,
} from './matchmaking.providers';
import { MatchingPersistenceModule } from '@contexts/matching/infrastructure/matching-persistence.module';
import { Module } from '@nestjs/common';

@Module({
  imports: [MatchingPersistenceModule],
  providers: matchmakingUseCaseProviders,
  exports: matchmakingUseCases,
})
export class MatchmakingApplicationModule {}

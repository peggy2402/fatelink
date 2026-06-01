import { matchesUseCaseProviders, matchesUseCases } from './matches.providers';
import { MatchingPersistenceModule } from '@contexts/matching/infrastructure/matching-persistence.module';
import { Module } from '@nestjs/common';

@Module({
  imports: [MatchingPersistenceModule],
  providers: matchesUseCaseProviders,
  exports: matchesUseCases,
})
export class MatchesApplicationModule {}

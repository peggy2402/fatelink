import { GetRecommendationsUseCase } from '@contexts/matching/application/usecases/get-recommendations.usecase';
import { MATCHMAKING_APPLICATION_TOKENS } from './matchmaking.tokens';
import { MATCH_CANDIDATE_REPOSITORY } from '@shared/kernel/injection-tokens';
import type { MatchCandidateRepository } from '@contexts/matching/domain/repositories/match-candidate.repository';
import type { Provider } from '@nestjs/common';

export const matchmakingUseCaseProviders: Provider[] = [
  {
    provide: MATCHMAKING_APPLICATION_TOKENS.getRecommendations,
    useFactory: (matchCandidateRepository: MatchCandidateRepository) =>
      new GetRecommendationsUseCase(matchCandidateRepository),
    inject: [MATCH_CANDIDATE_REPOSITORY],
  },
];

export const matchmakingUseCases = [
  MATCHMAKING_APPLICATION_TOKENS.getRecommendations,
];

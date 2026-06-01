import { UnmatchUsersUseCase } from '@contexts/matching/application/usecases/unmatch-users.usecase';
import { MATCHES_APPLICATION_TOKENS } from './matches.tokens';
import { MATCH_REPOSITORY } from '@shared/kernel/injection-tokens';
import type { MatchRepository } from '@contexts/matching/domain/repositories/match.repository';
import type { Provider } from '@nestjs/common';

export const matchesUseCaseProviders: Provider[] = [
  {
    provide: MATCHES_APPLICATION_TOKENS.unmatchUsers,
    useFactory: (matchRepository: MatchRepository) =>
      new UnmatchUsersUseCase(matchRepository),
    inject: [MATCH_REPOSITORY],
  },
];

export const matchesUseCases = [MATCHES_APPLICATION_TOKENS.unmatchUsers];

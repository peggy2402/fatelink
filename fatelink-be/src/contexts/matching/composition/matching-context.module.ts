import { Module } from '@nestjs/common';
import { AuthSecurityModule } from '@contexts/auth/composition/auth-security.module';
import { MatchmakingController } from '@contexts/matching/presentation/http/controllers/matchmaking.controller';
import { MatchesController } from '@contexts/matching/presentation/http/controllers/matches.controller';
import { MatchmakingApplicationModule } from './matchmaking-application.module';
import { MatchesApplicationModule } from './matches-application.module';

@Module({
  imports: [
    MatchmakingApplicationModule,
    MatchesApplicationModule,
    AuthSecurityModule,
  ],
  controllers: [MatchmakingController, MatchesController],
})
export class MatchingContextModule {}

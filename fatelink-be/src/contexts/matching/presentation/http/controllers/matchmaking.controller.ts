import { Controller, Get, Inject, Req, UseGuards } from '@nestjs/common';
import type { GetRecommendationsUseCase } from '@contexts/matching/application/usecases/get-recommendations.usecase';
import { JwtAuthGuard } from '@contexts/auth/presentation/http/guards/jwt-auth.guard';
import { MATCHMAKING_APPLICATION_TOKENS } from '@contexts/matching/composition/matchmaking.tokens';
import type { AuthenticatedRequest } from '@shared/presentation/types/authenticated-request';

@Controller('matchmaking')
@UseGuards(JwtAuthGuard) // Đã mở comment để bắt buộc có Token
export class MatchmakingController {
  constructor(
    @Inject(MATCHMAKING_APPLICATION_TOKENS.getRecommendations)
    private readonly getRecommendationsUseCase: GetRecommendationsUseCase,
  ) {}

  @Get('recommendations')
  async getRecommendations(@Req() req: AuthenticatedRequest) {
    return this.getRecommendationsUseCase.execute({ userId: req.user.sub });
  }
}

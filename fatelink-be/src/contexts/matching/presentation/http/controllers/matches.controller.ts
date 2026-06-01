import {
  Controller,
  Delete,
  Inject,
  Param,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { UnmatchUsersUseCase } from '@contexts/matching/application/usecases/unmatch-users.usecase';
import { JwtAuthGuard } from '@contexts/auth/presentation/http/guards/jwt-auth.guard';
import { MATCHES_APPLICATION_TOKENS } from '@contexts/matching/composition/matches.tokens';
import type { AuthenticatedRequest } from '@shared/presentation/types/authenticated-request';

@Controller('matches')
export class MatchesController {
  constructor(
    @Inject(MATCHES_APPLICATION_TOKENS.unmatchUsers)
    private readonly unmatchUsersUseCase: UnmatchUsersUseCase,
  ) {}

  @UseGuards(JwtAuthGuard)
  @Delete(':partnerId/unmatch')
  async unmatch(
    @Param('partnerId') partnerId: string,
    @Req() req: AuthenticatedRequest,
  ) {
    await this.unmatchUsersUseCase.execute({
      userId: req.user.sub,
      partnerId,
    });
    return { success: true, message: 'Đã huỷ ghép đôi thành công' };
  }
}

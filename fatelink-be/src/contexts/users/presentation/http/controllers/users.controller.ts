import {
  Controller,
  Get,
  Inject,
  Param,
  Post,
  UseGuards,
  Request,
  Body,
} from '@nestjs/common';
import { JwtAuthGuard } from '@contexts/auth/presentation/http/guards/jwt-auth.guard';
import type { AuthenticatedRequest } from '@shared/presentation/types/authenticated-request';
import type { FindEmotionMatchesUseCase } from '@contexts/users/application/usecases/find-emotion-matches.usecase';
import type { GetUserProfileUseCase } from '@contexts/users/application/usecases/get-user-profile.usecase';
import type { UpdateFcmTokenUseCase } from '@contexts/users/application/usecases/update-fcm-token.usecase';
import { USERS_APPLICATION_TOKENS } from '@contexts/users/composition/users.tokens';
import { UpdateFcmTokenDto } from '../dtos/users.request.dto';

@Controller('users')
export class UsersController {
  constructor(
    @Inject(USERS_APPLICATION_TOKENS.findEmotionMatches)
    private readonly findEmotionMatchesUseCase: FindEmotionMatchesUseCase,
    @Inject(USERS_APPLICATION_TOKENS.getUserProfile)
    private readonly getUserProfileUseCase: GetUserProfileUseCase,
    @Inject(USERS_APPLICATION_TOKENS.updateFcmToken)
    private readonly updateFcmTokenUseCase: UpdateFcmTokenUseCase,
  ) {}

  @Get(':id/matches')
  async getMatches(@Param('id') id: string) {
    return this.findEmotionMatchesUseCase.execute({ userId: id });
  }

  @Get(':id/profile')
  async getProfile(@Param('id') id: string) {
    return this.getUserProfileUseCase.execute({ userId: id });
  }

  @Post('fcm-token')
  @UseGuards(JwtAuthGuard) // Bảo vệ route bằng JWT
  async updateFcmToken(
    @Request() req: AuthenticatedRequest,
    @Body() dto: UpdateFcmTokenDto,
  ) {
    return this.updateFcmTokenUseCase.execute({
      userId: req.user.sub,
      fcmToken: dto.fcmToken,
    });
  }
}

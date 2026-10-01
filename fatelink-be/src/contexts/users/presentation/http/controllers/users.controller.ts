import {
  Controller,
  Get,
  Inject,
  Param,
  Post,
  Patch,
  UseGuards,
  Request,
  Body,
} from '@nestjs/common';
import { JwtAuthGuard } from '@contexts/auth/presentation/http/guards/jwt-auth.guard';
import type { AuthenticatedRequest } from '@shared/presentation/types/authenticated-request';
import type { FindEmotionMatchesUseCase } from '@contexts/users/application/usecases/find-emotion-matches.usecase';
import type { GetUserProfileUseCase } from '@contexts/users/application/usecases/get-user-profile.usecase';
import type { UpdateFcmTokenUseCase } from '@contexts/users/application/usecases/update-fcm-token.usecase';
import type { UpdateUserFrequencyUseCase } from '@contexts/users/application/usecases/update-user-frequency.usecase';
import { USERS_APPLICATION_TOKENS } from '@contexts/users/composition/users.tokens';
import { UpdateFcmTokenDto, UpdateFrequencyDto } from '../dtos/users.request.dto';

@Controller('users')
export class UsersController {
  constructor(
    @Inject(USERS_APPLICATION_TOKENS.findEmotionMatches)
    private readonly findEmotionMatchesUseCase: FindEmotionMatchesUseCase,
    @Inject(USERS_APPLICATION_TOKENS.getUserProfile)
    private readonly getUserProfileUseCase: GetUserProfileUseCase,
    @Inject(USERS_APPLICATION_TOKENS.updateFcmToken)
    private readonly updateFcmTokenUseCase: UpdateFcmTokenUseCase,
    @Inject(USERS_APPLICATION_TOKENS.updateUserFrequency)
    private readonly updateUserFrequencyUseCase: UpdateUserFrequencyUseCase,
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
  @UseGuards(JwtAuthGuard)
  async updateFcmToken(
    @Request() req: AuthenticatedRequest,
    @Body() dto: UpdateFcmTokenDto,
  ) {
    return this.updateFcmTokenUseCase.execute({
      userId: req.user.sub,
      fcmToken: dto.fcmToken,
    });
  }

  @Patch('frequency')
  @UseGuards(JwtAuthGuard)
  async updateFrequency(
    @Request() req: AuthenticatedRequest,
    @Body() dto: UpdateFrequencyDto,
  ) {
    return this.updateUserFrequencyUseCase.execute({
      userId: req.user.sub,
      ...dto,
    });
  }

  @Post('frequency')
  @UseGuards(JwtAuthGuard)
  async postFrequency(
    @Request() req: AuthenticatedRequest,
    @Body() dto: UpdateFrequencyDto,
  ) {
    return this.updateUserFrequencyUseCase.execute({
      userId: req.user.sub,
      ...dto,
    });
  }
}

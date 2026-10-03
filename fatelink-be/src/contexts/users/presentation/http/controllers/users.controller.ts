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
import type { UpdateUserProfileUseCase } from '@contexts/users/application/usecases/update-user-profile.usecase';
import { USERS_APPLICATION_TOKENS } from '@contexts/users/composition/users.tokens';
import {
  UpdateFcmTokenDto,
  UpdateFrequencyDto,
  UpdateUserProfileDto,
} from '../dtos/users.request.dto';

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
    @Inject(USERS_APPLICATION_TOKENS.updateUserProfile)
    private readonly updateUserProfileUseCase: UpdateUserProfileUseCase,
  ) {}

  @Get('me')
  @UseGuards(JwtAuthGuard)
  async getMyProfile(@Request() req: AuthenticatedRequest) {
    return this.getUserProfileUseCase.execute({ userId: req.user.sub });
  }

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

  @Patch('profile')
  @UseGuards(JwtAuthGuard)
  async updateProfile(
    @Request() req: AuthenticatedRequest,
    @Body() dto: UpdateUserProfileDto,
  ) {
    return this.updateUserProfileUseCase.execute({
      userId: req.user.sub,
      name: dto.name,
      handle: dto.handle,
      avatar: dto.avatar,
      bio: dto.bio,
      gender: dto.gender,
      dateOfBirth: dto.dateOfBirth,
      address: dto.address,
      isFaceLocked: dto.isFaceLocked,
      vibePhotos: dto.vibePhotos?.map((p) => ({
        id: p.id,
        imageUrl: p.imageUrl,
        createdAt: p.createdAt ? new Date(p.createdAt) : new Date(),
        durationMinutes: p.durationMinutes ?? 1440,
        expiresAt: new Date(p.expiresAt),
      })),
    });
  }

  @Post('profile')
  @UseGuards(JwtAuthGuard)
  async postProfile(
    @Request() req: AuthenticatedRequest,
    @Body() dto: UpdateUserProfileDto,
  ) {
    return this.updateProfile(req, dto);
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

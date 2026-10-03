import {
  Controller,
  Get,
  Inject,
  Param,
  Post,
  Patch,
  Delete,
  UseGuards,
  Request,
  Body,
} from '@nestjs/common';
import { JwtAuthGuard } from '@contexts/auth/presentation/http/guards/jwt-auth.guard';
import type { AuthenticatedRequest } from '@shared/presentation/types/authenticated-request';
import { USER_REPOSITORY } from '@shared/kernel/injection-tokens';
import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';
import type { FindEmotionMatchesUseCase } from '@contexts/users/application/usecases/find-emotion-matches.usecase';
import type { GetUserProfileUseCase } from '@contexts/users/application/usecases/get-user-profile.usecase';
import type { UpdateFcmTokenUseCase } from '@contexts/users/application/usecases/update-fcm-token.usecase';
import type { UpdateUserFrequencyUseCase } from '@contexts/users/application/usecases/update-user-frequency.usecase';
import type { UpdateUserProfileUseCase } from '@contexts/users/application/usecases/update-user-profile.usecase';
import type { RecordProfileViewUseCase } from '@contexts/users/application/usecases/record-profile-view.usecase';
import type { ToggleUserLikeUseCase } from '@contexts/users/application/usecases/toggle-user-like.usecase';
import type { RecordWaveUseCase } from '@contexts/users/application/usecases/record-wave.usecase';
import type { GetNotificationsUseCase } from '@contexts/users/application/usecases/get-notifications.usecase';
import type { MarkNotificationReadUseCase } from '@contexts/users/application/usecases/mark-notification-read.usecase';
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
    @Inject(USERS_APPLICATION_TOKENS.recordProfileView)
    private readonly recordProfileViewUseCase: RecordProfileViewUseCase,
    @Inject(USERS_APPLICATION_TOKENS.toggleUserLike)
    private readonly toggleUserLikeUseCase: ToggleUserLikeUseCase,
    @Inject(USERS_APPLICATION_TOKENS.recordWave)
    private readonly recordWaveUseCase: RecordWaveUseCase,
    @Inject(USERS_APPLICATION_TOKENS.getNotifications)
    private readonly getNotificationsUseCase: GetNotificationsUseCase,
    @Inject(USERS_APPLICATION_TOKENS.markNotificationRead)
    private readonly markNotificationReadUseCase: MarkNotificationReadUseCase,
    @Inject(USER_REPOSITORY)
    private readonly userRepository: UserRepository,
  ) {}

  @Get('me')
  @UseGuards(JwtAuthGuard)
  async getMyProfile(@Request() req: AuthenticatedRequest) {
    return this.getUserProfileUseCase.execute({ userId: req.user.sub });
  }

  @Get('notifications')
  @UseGuards(JwtAuthGuard)
  async getMyNotifications(@Request() req: AuthenticatedRequest) {
    return this.getNotificationsUseCase.execute({ userId: req.user.sub });
  }

  @Patch('notifications/read-all')
  @UseGuards(JwtAuthGuard)
  async markAllNotificationsRead(@Request() req: AuthenticatedRequest) {
    return this.markNotificationReadUseCase.execute({
      userId: req.user.sub,
      markAll: true,
    });
  }

  @Patch('notifications/:notificationId/read')
  @UseGuards(JwtAuthGuard)
  async markNotificationRead(
    @Request() req: AuthenticatedRequest,
    @Param('notificationId') notificationId: string,
  ) {
    return this.markNotificationReadUseCase.execute({
      userId: req.user.sub,
      notificationId,
    });
  }

  @Get(':id/matches')
  async getMatches(@Param('id') id: string) {
    return this.findEmotionMatchesUseCase.execute({ userId: id });
  }

  @Get(':id/profile')
  async getProfile(@Param('id') id: string) {
    return this.getUserProfileUseCase.execute({ userId: id });
  }

  @Post(':id/view')
  @UseGuards(JwtAuthGuard)
  async recordProfileView(
    @Request() req: AuthenticatedRequest,
    @Param('id') id: string,
  ) {
    return this.recordProfileViewUseCase.execute({
      targetUserId: id,
      viewerId: req.user.sub,
    });
  }

  @Post(':id/like')
  @UseGuards(JwtAuthGuard)
  async toggleLike(
    @Request() req: AuthenticatedRequest,
    @Param('id') id: string,
  ) {
    return this.toggleUserLikeUseCase.execute({
      targetUserId: id,
      likerId: req.user.sub,
    });
  }

  @Post(':id/wave')
  @UseGuards(JwtAuthGuard)
  async recordWave(
    @Request() req: AuthenticatedRequest,
    @Param('id') id: string,
  ) {
    return this.recordWaveUseCase.execute({
      targetUserId: id,
      senderId: req.user.sub,
    });
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

  @Get('blocked')
  @UseGuards(JwtAuthGuard)
  async getBlockedUsers(@Request() req: AuthenticatedRequest) {
    return this.userRepository.getBlockedUsers(req.user.sub);
  }

  @Post(':id/block')
  @UseGuards(JwtAuthGuard)
  async blockUser(
    @Request() req: AuthenticatedRequest,
    @Param('id') targetUserId: string,
  ) {
    const success = await this.userRepository.blockUser(req.user.sub, targetUserId);
    return { success, message: 'Đã chặn người dùng thành công' };
  }

  @Delete(':id/unblock')
  @UseGuards(JwtAuthGuard)
  async unblockUser(
    @Request() req: AuthenticatedRequest,
    @Param('id') targetUserId: string,
  ) {
    const success = await this.userRepository.unblockUser(req.user.sub, targetUserId);
    return { success, message: 'Đã bỏ chặn người dùng thành công' };
  }

  @Post(':id/report')
  @UseGuards(JwtAuthGuard)
  async reportUser(
    @Request() req: AuthenticatedRequest,
    @Param('id') targetUserId: string,
    @Body() body: { reason: string; details?: string; blockAlso?: boolean },
  ) {
    await this.userRepository.createReport({
      reporterId: req.user.sub,
      targetUserId,
      reason: body.reason,
      details: body.details,
    });

    if (body.blockAlso) {
      await this.userRepository.blockUser(req.user.sub, targetUserId);
    }

    return { success: true, message: 'Đã gửi báo cáo vi phạm thành công' };
  }
}

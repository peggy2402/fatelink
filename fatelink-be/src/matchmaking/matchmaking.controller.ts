import { Controller, Get, Req, UseGuards } from '@nestjs/common';
import { MatchmakingService } from './matchmaking.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard'; // Đã mở comment

@Controller('matchmaking')
@UseGuards(JwtAuthGuard) // Đã mở comment để bắt buộc có Token
export class MatchmakingController {
  constructor(private readonly matchmakingService: MatchmakingService) {}

  @Get('recommendations')
  async getRecommendations(@Req() req) {
    // Đã fix lỗi Cast to ObjectId: Thay 'temp-id' bằng ID thật của user.
    // Lưu ý: Bạn cần mở comment @UseGuards(JwtAuthGuard) ở trên class để req có object user
    const userId = req.user?.id || req.user?.sub;
    if (!userId) throw new Error('Không tìm thấy thông tin người dùng trong Token');

    return this.matchmakingService.getRecommendations(userId);
  }
}

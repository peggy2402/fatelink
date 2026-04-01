import { Controller, Get, Req, UseGuards } from '@nestjs/common';
import { MatchmakingService } from './matchmaking.service';
// import { JwtAuthGuard } from '../auth/jwt-auth.guard'; // Bảo vệ API

@Controller('matchmaking')
// @UseGuards(JwtAuthGuard)
export class MatchmakingController {
  constructor(private readonly matchmakingService: MatchmakingService) {}

  @Get('recommendations')
  async getRecommendations(@Req() req) {
    // const userId = req.user.id; // Lấy ID từ JWT token
    const userId = 'temp-id'; // Tạm thời hardcode
    return this.matchmakingService.getRecommendations(userId);
  }
}

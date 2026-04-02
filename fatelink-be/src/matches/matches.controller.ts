// matches.controller.ts
import { Controller, Delete, Param, Req, UseGuards } from '@nestjs/common';
import { MatchesService } from './matches.service';
// import { JwtAuthGuard } from '../auth/jwt-auth.guard'; // Tuỳ vào Auth Guard của bạn

@Controller('matches')
export class MatchesController {
  constructor(private readonly matchesService: MatchesService) {}

  // @UseGuards(JwtAuthGuard)
  @Delete(':partnerId/unmatch')
  async unmatch(@Param('partnerId') partnerId: string, @Req() req: any) {
    const userId = req.user.id; // Lấy từ token người dùng hiện tại
    await this.matchesService.unmatchUsers(userId, partnerId);
    return { success: true, message: 'Đã huỷ ghép đôi thành công' };
  }
}

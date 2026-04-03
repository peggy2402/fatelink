import { Controller, Get, Param, Post, UseGuards, Request, Body } from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get(':id/matches')
  async getMatches(@Param('id') id: string) {
    return this.usersService.findMatches(id);
  }

  @Get(':id/profile')
  async getProfile(@Param('id') id: string) {
    return this.usersService.findById(id);
  }

  @Post('fcm-token')
  @UseGuards(JwtAuthGuard) // Bảo vệ route bằng JWT
  async updateFcmToken(@Request() req, @Body('fcmToken') fcmToken: string) {
    // req.user chứa thông tin từ JWT Token sau khi giải mã
    return this.usersService.updateFcmToken(req.user.userId, fcmToken);
  }
}
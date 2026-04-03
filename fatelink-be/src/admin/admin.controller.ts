import { Controller, Get, Put, Post, Body, Param, UseGuards } from '@nestjs/common';
import { AdminService } from './admin.service';
import { AdminGuard } from './guards/admin.guard';

@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Post('login')
  login(@Body() body: any) {
    return this.adminService.login(body.username, body.password);
  }

  @UseGuards(AdminGuard)
  @Get('config')
  getConfig() {
    return this.adminService.getConfig();
  }

  @UseGuards(AdminGuard)
  @Put('config')
  updateConfig(@Body() updateData: any) {
    return this.adminService.updateConfig(updateData);
  }

  @UseGuards(AdminGuard)
  @Get('users')
  getUsers() {
    return this.adminService.getUsers();
  }

  @UseGuards(AdminGuard)
  @Put('users/:id/ban')
  banUser(@Param('id') id: string, @Body('isBanned') isBanned: boolean) {
    return this.adminService.banUser(id, isBanned);
  }
}
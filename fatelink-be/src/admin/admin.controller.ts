import { Controller, Get, Put, Body, UseGuards } from '@nestjs/common';
import { AdminService } from './admin.service';
// import { JwtAuthGuard, RolesGuard, Roles } from '../auth/guards'; // Nhớ thêm Guard để bảo mật

@Controller('admin')
// @UseGuards(JwtAuthGuard, RolesGuard)
// @Roles('admin') // Chỉ cho phép user có role 'admin' truy cập
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('config')
  getConfig() {
    return this.adminService.getConfig();
  }

  @Put('config')
  updateConfig(@Body() updateData: any) {
    return this.adminService.updateConfig(updateData);
  }
}
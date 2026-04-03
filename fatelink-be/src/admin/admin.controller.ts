import { Controller, Get, Put, Post, Delete, Body, Param, UseGuards, HttpCode, HttpStatus } from '@nestjs/common';
import { AdminService } from './admin.service';
import { AdminGuard } from './guards/admin.guard';
import { AdminLoginDto } from './dto/admin-login.dto';
import { AiService } from '../ai/ai.service';

@Controller('admin')
export class AdminController {
  constructor(
    private readonly adminService: AdminService,
    private readonly aiService: AiService,
  ) {}

  @Post('login')
  @HttpCode(HttpStatus.OK) // Thay đổi mặc định 201 Created thành 200 OK
  login(@Body() loginDto: AdminLoginDto) {
    return this.adminService.login(loginDto.username, loginDto.password);
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

  @UseGuards(AdminGuard)
  @Get('ai-status')
  checkAiStatus() {
    return this.aiService.checkProvidersStatus();
  }

  // --- API CRUD cho AI Models ---
  @UseGuards(AdminGuard)
  @Get('models')
  getAiModels() {
    return this.adminService.getAiModels();
  }

  @UseGuards(AdminGuard)
  @Post('models')
  createAiModel(@Body() dto: any) {
    return this.adminService.createAiModel(dto);
  }

  @UseGuards(AdminGuard)
  @Put('models/:id')
  updateAiModel(@Param('id') id: string, @Body() dto: any) {
    return this.adminService.updateAiModel(id, dto);
  }

  @UseGuards(AdminGuard)
  @Delete('models/:id')
  deleteAiModel(@Param('id') id: string) {
    return this.adminService.deleteAiModel(id);
  }
}
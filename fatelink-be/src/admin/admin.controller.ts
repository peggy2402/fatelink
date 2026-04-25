import {
  Controller,
  Get,
  Put,
  Post,
  Delete,
  Body,
  Param,
  UseGuards,
  HttpCode,
  HttpStatus,
  Res,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiBody,
  ApiParam,
} from '@nestjs/swagger';
import { AdminService } from './admin.service';
import { AdminGuard } from './guards/admin.guard';
import { AdminLoginDto } from './dto/admin-login.dto';
import { AiService } from '../ai/ai.service';
import * as fs from 'fs';
import * as path from 'path';
import type { Response } from 'express';

@ApiTags('Admin Dashboard')
@Controller('admin')
export class AdminController {
  constructor(
    private readonly adminService: AdminService,
    private readonly aiService: AiService,
  ) {}

  @Post('login')
  @HttpCode(HttpStatus.OK) // Thay đổi mặc định 201 Created thành 200 OK
  @ApiOperation({ summary: 'Đăng nhập vào trang Quản trị' })
  @ApiResponse({ status: 200, description: 'Đăng nhập thành công, trả về JWT Token' })
  @ApiResponse({ status: 401, description: 'Sai tài khoản hoặc mật khẩu' })
  login(@Body() loginDto: AdminLoginDto) {
    return this.adminService.login(loginDto.username, loginDto.password);
  }

  @ApiBearerAuth()
  @UseGuards(AdminGuard)
  @Get('config')
  @ApiOperation({ summary: 'Lấy cấu hình hệ thống (System Prompt, Knowledge...)' })
  getConfig() {
    return this.adminService.getConfig();
  }

  @ApiBearerAuth()
  @UseGuards(AdminGuard)
  @Put('config')
  @ApiOperation({ summary: 'Cập nhật cấu hình hệ thống' })
  updateConfig(@Body() updateData: any) {
    return this.adminService.updateConfig(updateData);
  }

  @ApiBearerAuth()
  @UseGuards(AdminGuard)
  @Get('users')
  @ApiOperation({ summary: 'Lấy danh sách người dùng' })
  getUsers() {
    return this.adminService.getUsers();
  }

  @ApiBearerAuth()
  @UseGuards(AdminGuard)
  @Put('users/:id/ban')
  @ApiOperation({ summary: 'Khóa / Mở khóa tài khoản người dùng' })
  @ApiParam({ name: 'id', description: 'ID của người dùng' })
  @ApiBody({ schema: { type: 'object', properties: { isBanned: { type: 'boolean', example: true } } } })
  banUser(@Param('id') id: string, @Body('isBanned') isBanned: boolean) {
    return this.adminService.banUser(id, isBanned);
  }

  @ApiBearerAuth()
  @UseGuards(AdminGuard)
  @Get('ai-status')
  @ApiOperation({ summary: 'Kiểm tra trạng thái sức khỏe (Ping) của các Model AI' })
  checkAiStatus() {
    return this.aiService.checkProvidersStatus();
  }

  // --- API CRUD cho AI Models ---
  @ApiBearerAuth()
  @UseGuards(AdminGuard)
  @Get('models')
  @ApiOperation({ summary: 'Lấy danh sách các Model AI đang cấu hình' })
  getAiModels() {
    return this.adminService.getAiModels();
  }

  @ApiBearerAuth()
  @UseGuards(AdminGuard)
  @Post('models')
  @ApiOperation({ summary: 'Thêm mới một Model AI' })
  createAiModel(@Body() dto: any) {
    return this.adminService.createAiModel(dto);
  }

  @ApiBearerAuth()
  @UseGuards(AdminGuard)
  @Put('models/:id')
  @ApiOperation({ summary: 'Cập nhật thông tin Model AI' })
  @ApiParam({ name: 'id', description: 'ID của AI Model' })
  updateAiModel(@Param('id') id: string, @Body() dto: any) {
    return this.adminService.updateAiModel(id, dto);
  }

  @ApiBearerAuth()
  @UseGuards(AdminGuard)
  @Delete('models/:id')
  @ApiOperation({ summary: 'Xóa Model AI khỏi hệ thống' })
  @ApiParam({ name: 'id', description: 'ID của AI Model' })
  deleteAiModel(@Param('id') id: string) {
    return this.adminService.deleteAiModel(id);
  }

  @ApiBearerAuth()
  @UseGuards(AdminGuard)
  @Put('models/reorder')
  @ApiOperation({ summary: 'Sắp xếp lại thứ tự ưu tiên (Priority) của các Model AI' })
  @ApiBody({ schema: { type: 'object', properties: { modelIds: { type: 'array', items: { type: 'string' } } } } })
  reorderAiModels(@Body('modelIds') modelIds: string[]): Promise<any> {
    return this.adminService.reorderAiModels(modelIds);
  }

  @ApiBearerAuth()
  @UseGuards(AdminGuard)
  @Post('ai-chat')
  @ApiOperation({ summary: 'Khung chat giả lập trên Dashboard để test thử System Prompt' })
  @ApiBody({ schema: { type: 'object', properties: { message: { type: 'string', example: 'Chào cậu!' } } } })
  testAiChat(@Body('message') message: string) {
    // Gọi hàm chat của AI, lịch sử truyền rỗng để tập trung test System Prompt
    return this.aiService.sendMessage(message, []);
  }

  @ApiBearerAuth()
  @UseGuards(AdminGuard)
  @Post('logs')
  @ApiOperation({ summary: 'Ghi log lỗi hiển thị từ Admin Dashboard xuống file' })
  @ApiBody({ schema: { type: 'object', properties: { message: { type: 'string' }, type: { type: 'string', example: 'ERROR' } } } })
  saveLog(@Body('message') message: string, @Body('type') type: string) {
    const logLine = `[${new Date().toISOString()}] [${type}] ${message}\n`;
    const logPath = path.join(process.cwd(), 'admin_logs.txt');
    // Ghi nối tiếp vào cuối file
    fs.appendFileSync(logPath, logLine);
    return { success: true };
  }

  @ApiBearerAuth()
  @UseGuards(AdminGuard)
  @Get('logs/download')
  @ApiOperation({ summary: 'Tải xuống toàn bộ file admin_logs.txt' })
  downloadLogs(@Res() res: Response) {
    const logPath = path.join(process.cwd(), 'admin_logs.txt');
    if (fs.existsSync(logPath)) {
      res.download(logPath, 'fatelink_admin_logs.txt');
    } else {
      res.status(404).send('Chưa có file log nào được tạo.');
    }
  }
}
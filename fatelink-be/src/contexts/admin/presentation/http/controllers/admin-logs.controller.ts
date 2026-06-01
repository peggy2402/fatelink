import {
  Body,
  Controller,
  Get,
  Inject,
  NotFoundException,
  Post,
  Res,
  UseGuards,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { AdminGuard } from '@contexts/auth/presentation/http/guards/admin.guard';
import type { GetAdminLogFileUseCase } from '@contexts/admin/application/usecases/get-admin-log-file.usecase';
import type { SaveAdminLogUseCase } from '@contexts/admin/application/usecases/save-admin-log.usecase';
import { ADMIN_APPLICATION_TOKENS } from '@contexts/admin/composition/admin.tokens';
import {
  ApiAdminProtected,
  ApiDownloadAdminLogs,
  ApiSaveAdminLog,
} from '@contexts/admin/presentation/http/docs/admin.swagger';
import type { Response } from 'express';
import { SaveAdminLogDto } from '../dtos/admin.request.dto';

@ApiTags('Admin Logs')
@ApiAdminProtected()
@UseGuards(AdminGuard)
@Controller('admin/logs')
export class AdminLogsController {
  constructor(
    @Inject(ADMIN_APPLICATION_TOKENS.saveAdminLog)
    private readonly saveAdminLogUseCase: SaveAdminLogUseCase,
    @Inject(ADMIN_APPLICATION_TOKENS.getAdminLogFile)
    private readonly getAdminLogFileUseCase: GetAdminLogFileUseCase,
  ) {}

  @Post()
  @ApiSaveAdminLog()
  saveLog(@Body() dto: SaveAdminLogDto) {
    return this.saveAdminLogUseCase.execute(dto);
  }

  @Get('download')
  @ApiDownloadAdminLogs()
  downloadLogs(@Res() res: Response) {
    const file = this.getAdminLogFileUseCase.execute();
    if (!file) {
      throw new NotFoundException('Chua co file log nao duoc tao.');
    }

    res.download(file.path, file.filename);
  }
}

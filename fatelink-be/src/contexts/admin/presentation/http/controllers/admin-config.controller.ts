import { Body, Controller, Get, Inject, Put, UseGuards } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { AdminGuard } from '@contexts/auth/presentation/http/guards/admin.guard';
import type { GetSystemConfigUseCase } from '@contexts/admin/application/usecases/get-system-config.usecase';
import type { UpdateSystemConfigUseCase } from '@contexts/admin/application/usecases/update-system-config.usecase';
import { ADMIN_APPLICATION_TOKENS } from '@contexts/admin/composition/admin.tokens';
import {
  ApiAdminProtected,
  ApiGetSystemConfig,
  ApiUpdateSystemConfig,
} from '@contexts/admin/presentation/http/docs/admin.swagger';
import { UpdateSystemConfigDto } from '../dtos/admin.request.dto';

@ApiTags('Admin Config')
@ApiAdminProtected()
@UseGuards(AdminGuard)
@Controller('admin/config')
export class AdminConfigController {
  constructor(
    @Inject(ADMIN_APPLICATION_TOKENS.getSystemConfig)
    private readonly getSystemConfigUseCase: GetSystemConfigUseCase,
    @Inject(ADMIN_APPLICATION_TOKENS.updateSystemConfig)
    private readonly updateSystemConfigUseCase: UpdateSystemConfigUseCase,
  ) {}

  @Get()
  @ApiGetSystemConfig()
  getConfig() {
    return this.getSystemConfigUseCase.execute();
  }

  @Put()
  @ApiUpdateSystemConfig()
  updateConfig(@Body() updateData: UpdateSystemConfigDto) {
    return this.updateSystemConfigUseCase.execute(updateData);
  }
}

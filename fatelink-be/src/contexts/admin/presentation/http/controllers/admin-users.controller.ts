import {
  Body,
  Controller,
  Get,
  Inject,
  Param,
  Put,
  UseGuards,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { AdminGuard } from '@contexts/auth/presentation/http/guards/admin.guard';
import type { AdminBanUserUseCase } from '@contexts/admin/application/usecases/admin-ban-user.usecase';
import type { AdminListUsersUseCase } from '@contexts/admin/application/usecases/admin-list-users.usecase';
import { ADMIN_APPLICATION_TOKENS } from '@contexts/admin/composition/admin.tokens';
import {
  ApiAdminBanUser,
  ApiAdminListUsers,
  ApiAdminProtected,
} from '@contexts/admin/presentation/http/docs/admin.swagger';
import { BanUserDto } from '../dtos/admin.request.dto';

@ApiTags('Admin Users')
@ApiAdminProtected()
@UseGuards(AdminGuard)
@Controller('admin/users')
export class AdminUsersController {
  constructor(
    @Inject(ADMIN_APPLICATION_TOKENS.listUsers)
    private readonly adminListUsersUseCase: AdminListUsersUseCase,
    @Inject(ADMIN_APPLICATION_TOKENS.banUser)
    private readonly adminBanUserUseCase: AdminBanUserUseCase,
  ) {}

  @Get()
  @ApiAdminListUsers()
  getUsers() {
    return this.adminListUsersUseCase.execute();
  }

  @Put(':id/ban')
  @ApiAdminBanUser()
  banUser(@Param('id') id: string, @Body() dto: BanUserDto) {
    return this.adminBanUserUseCase.execute({
      userId: id,
      isBanned: dto.isBanned,
    });
  }
}

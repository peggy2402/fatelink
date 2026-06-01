import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Inject,
  Post,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import type { AdminLoginUseCase } from '@contexts/admin/application/usecases/admin-login.usecase';
import { ADMIN_APPLICATION_TOKENS } from '@contexts/admin/composition/admin.tokens';
import { ApiAdminLogin } from '@contexts/admin/presentation/http/docs/admin.swagger';
import { AdminLoginDto } from '../dtos/admin.request.dto';

@ApiTags('Admin Auth')
@Controller('admin')
export class AdminAuthController {
  constructor(
    @Inject(ADMIN_APPLICATION_TOKENS.login)
    private readonly adminLoginUseCase: AdminLoginUseCase,
  ) {}

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiAdminLogin()
  login(@Body() loginDto: AdminLoginDto) {
    return this.adminLoginUseCase.execute(loginDto);
  }
}

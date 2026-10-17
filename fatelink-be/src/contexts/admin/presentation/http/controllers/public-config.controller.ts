import { Controller, Get, Inject } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import type { GetSystemConfigUseCase } from '@contexts/admin/application/usecases/get-system-config.usecase';
import { ADMIN_APPLICATION_TOKENS } from '@contexts/admin/composition/admin.tokens';

@ApiTags('Public Config')
@Controller('app-config')
export class PublicConfigController {
  constructor(
    @Inject(ADMIN_APPLICATION_TOKENS.getSystemConfig)
    private readonly getSystemConfigUseCase: GetSystemConfigUseCase,
  ) {}

  @Get()
  @ApiOperation({
    summary: 'Lấy cấu hình public của ứng dụng (Social Auth providers, App info)',
  })
  @ApiResponse({
    status: 200,
    description: 'Cấu hình public an toàn cho mobile app',
  })
  async getPublicConfig() {
    const config = await this.getSystemConfigUseCase.execute();
    const social = config.socialAuth || {};

    return {
      status: 'success',
      data: {
        facebook: {
          enabled: social.facebook?.enabled ?? true,
          appId: social.facebook?.appId || '',
          clientToken: social.facebook?.clientToken || '',
        },
        google: {
          enabled: social.google?.enabled ?? true,
          clientId:
            social.google?.clientId ||
            '918573554808-07stv5tp2474icsh5f47mvop9vaa9sug.apps.googleusercontent.com',
          iosClientId: social.google?.iosClientId || '',
        },
        zalo: {
          enabled: social.zalo?.enabled ?? true,
          appId: social.zalo?.appId || '3205454775701109337',
        },
        tiktok: {
          enabled: social.tiktok?.enabled ?? true,
          clientKey: social.tiktok?.clientKey || '',
        },
        onboardingMessageLimit: config.onboardingMessageLimit || 10,
      },
    };
  }
}

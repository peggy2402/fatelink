import {
  ADMIN_CREDENTIAL_SERVICE,
  GOOGLE_AUTH_SERVICE,
  TOKEN_SERVICE,
} from '@shared/kernel/injection-tokens';
import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { EnvAdminCredentialServiceImpl } from './services/env-admin-credential.service.impl';
import { GoogleAuthServiceImpl } from './services/google-auth.service.impl';
import { JwtTokenServiceImpl } from './services/jwt-token.service.impl';

@Module({
  imports: [JwtModule.register({})],
  providers: [
    {
      provide: GOOGLE_AUTH_SERVICE,
      useClass: GoogleAuthServiceImpl,
    },
    {
      provide: TOKEN_SERVICE,
      useClass: JwtTokenServiceImpl,
    },
    {
      provide: ADMIN_CREDENTIAL_SERVICE,
      useClass: EnvAdminCredentialServiceImpl,
    },
  ],
  exports: [GOOGLE_AUTH_SERVICE, TOKEN_SERVICE, ADMIN_CREDENTIAL_SERVICE],
})
export class AuthInfrastructureModule {}

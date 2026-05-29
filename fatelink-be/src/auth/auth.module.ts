import { Module } from '@nestjs/common';
import { AuthService } from './auth.service';
import { UsersModule } from '../users/users.module';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { StringValue } from 'ms';
import { JwtAuthGuard } from './jwt-auth.guard';
import { LegacyAuthController } from './legacy/legacy-auth.controller';
import { LegacyAuthService } from './legacy/legacy-auth.service';
import { LegacyJwtAuthGuard } from './legacy/legacy-jwt-auth.guard';
import { AUTH_ENV } from './shared/auth.constants';
import { GoogleController } from './v2/google/google.controller';
import { GoogleService } from './v2/google/google.service';
import { SecurityController } from './v2/security/security.controller';
import { SecurityService } from './v2/security/security.service';
import { AuthTokenService } from './v2/services/auth-token.service';
import { AuthUserService } from './v2/services/auth-user.service';
import { GoogleTokenService } from './v2/services/google-token.service';
import { RefreshTokenStoreService } from './v2/services/refresh-token-store.service';

@Module({
  imports: [
    ConfigModule,
    UsersModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        secret: configService.getOrThrow<string>(AUTH_ENV.JWT_SECRET),
        signOptions: {
          expiresIn: configService.getOrThrow<StringValue>(
            AUTH_ENV.ACCESS_TOKEN_EXPIRES_IN,
          ),
        },
      }),
    }),
  ],
  controllers: [LegacyAuthController, GoogleController, SecurityController],
  providers: [
    AuthService,
    JwtAuthGuard,
    LegacyAuthService,
    LegacyJwtAuthGuard,
    GoogleService,
    SecurityService,
    AuthTokenService,
    AuthUserService,
    GoogleTokenService,
    RefreshTokenStoreService,
  ],
  exports: [JwtModule, AuthService, JwtAuthGuard], // Export để các module khác có thể sử dụng JwtService
})
export class AuthModule {}

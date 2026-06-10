import {
  ADMIN_CREDENTIAL_SERVICE,
  EMAIL_DELIVERY_SERVICE,
  EMAIL_AUTH_SERVICE,
  FACEBOOK_AUTH_SERVICE,
  GOOGLE_AUTH_SERVICE,
  MAGIC_LINK_AUTH_SERVICE,
  PHONE_AUTH_SERVICE,
  PHONE_OTP_DELIVERY_SERVICE,
  USER_REPOSITORY,
  TOKEN_SERVICE,
} from '@shared/kernel/injection-tokens';
import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { MongooseModule } from '@nestjs/mongoose';
import type { EmailDeliveryService } from '@shared/contracts/email-delivery.service';
import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';
import { EnvAdminCredentialServiceImpl } from './services/env-admin-credential.service.impl';
import { EmailAuthServiceImpl } from './services/email-auth.service.impl';
import { FacebookAuthServiceImpl } from './services/facebook-auth.service.impl';
import { GoogleAuthServiceImpl } from './services/google-auth.service.impl';
import { GoogleEmailDeliveryServiceImpl } from './services/google-email-delivery.service.impl';
import { JwtTokenServiceImpl } from './services/jwt-token.service.impl';
import { MagicLinkAuthServiceImpl } from './services/magic-link-auth.service.impl';
import { TwilioPhoneOtpDeliveryServiceImpl } from './services/twilio-phone-otp-delivery.service.impl';
import {
  AuthChallenge,
  AuthChallengeSchema,
} from './models/auth-challenge.model';
import { AuthIdentity, AuthIdentitySchema } from './models/auth-identity.model';
import { AuthSession, AuthSessionSchema } from './models/auth-session.model';
import { MongooseAuthChallengeRepository } from './repositories/mongoose-auth-challenge.repository';
import { MongooseAuthIdentityRepository } from './repositories/mongoose-auth-identity.repository';
import { MongooseAuthSessionRepository } from './repositories/mongoose-auth-session.repository';
import { PhoneAuthServiceImpl } from './services/phone-auth.service.impl';
import { SecretHashService } from './services/secret-hash.service';
import { UsersPersistenceModule } from '@contexts/users/infrastructure/users-persistence.module';

@Module({
  imports: [
    JwtModule.register({}),
    ConfigModule,
    UsersPersistenceModule,
    MongooseModule.forFeature([
      { name: AuthIdentity.name, schema: AuthIdentitySchema },
      { name: AuthChallenge.name, schema: AuthChallengeSchema },
      { name: AuthSession.name, schema: AuthSessionSchema },
    ]),
  ],
  providers: [
    SecretHashService,
    MongooseAuthIdentityRepository,
    MongooseAuthChallengeRepository,
    MongooseAuthSessionRepository,
    {
      provide: GOOGLE_AUTH_SERVICE,
      useFactory: (configService: ConfigService) =>
        new GoogleAuthServiceImpl(configService),
      inject: [ConfigService],
    },
    {
      provide: FACEBOOK_AUTH_SERVICE,
      useFactory: (configService: ConfigService) =>
        new FacebookAuthServiceImpl(configService),
      inject: [ConfigService],
    },
    {
      provide: EMAIL_AUTH_SERVICE,
      useFactory: (
        userRepository: UserRepository,
        authIdentityRepository: MongooseAuthIdentityRepository,
        secretHashService: SecretHashService,
      ) =>
        new EmailAuthServiceImpl(
          userRepository,
          authIdentityRepository,
          secretHashService,
        ),
      inject: [
        USER_REPOSITORY,
        MongooseAuthIdentityRepository,
        SecretHashService,
      ],
    },
    {
      provide: EMAIL_DELIVERY_SERVICE,
      // TODO: Tách provider email ra module/context riêng khi có thêm verify email,
      // forgot password, notification hoặc nhiều kênh gửi khác.
      useFactory: (configService: ConfigService) =>
        new GoogleEmailDeliveryServiceImpl(configService),
      inject: [ConfigService],
    },
    {
      provide: PHONE_OTP_DELIVERY_SERVICE,
      useFactory: (configService: ConfigService) =>
        new TwilioPhoneOtpDeliveryServiceImpl(configService),
      inject: [ConfigService],
    },
    {
      provide: PHONE_AUTH_SERVICE,
      useFactory: (
        userRepository: UserRepository,
        authIdentityRepository: MongooseAuthIdentityRepository,
        authChallengeRepository: MongooseAuthChallengeRepository,
        configService: ConfigService,
        secretHashService: SecretHashService,
        phoneOtpDeliveryService: TwilioPhoneOtpDeliveryServiceImpl,
      ) =>
        new PhoneAuthServiceImpl(
          userRepository,
          authIdentityRepository,
          authChallengeRepository,
          configService,
          secretHashService,
          phoneOtpDeliveryService,
        ),
      inject: [
        USER_REPOSITORY,
        MongooseAuthIdentityRepository,
        MongooseAuthChallengeRepository,
        ConfigService,
        SecretHashService,
        PHONE_OTP_DELIVERY_SERVICE,
      ],
    },
    {
      provide: MAGIC_LINK_AUTH_SERVICE,
      useFactory: (
        userRepository: UserRepository,
        authChallengeRepository: MongooseAuthChallengeRepository,
        configService: ConfigService,
        secretHashService: SecretHashService,
        emailDeliveryService: EmailDeliveryService,
      ) =>
        new MagicLinkAuthServiceImpl(
          userRepository,
          authChallengeRepository,
          configService,
          secretHashService,
          emailDeliveryService,
        ),
      inject: [
        USER_REPOSITORY,
        MongooseAuthChallengeRepository,
        ConfigService,
        SecretHashService,
        EMAIL_DELIVERY_SERVICE,
      ],
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
  exports: [
    MongooseAuthIdentityRepository,
    MongooseAuthChallengeRepository,
    MongooseAuthSessionRepository,
    GOOGLE_AUTH_SERVICE,
    FACEBOOK_AUTH_SERVICE,
    EMAIL_AUTH_SERVICE,
    EMAIL_DELIVERY_SERVICE,
    PHONE_AUTH_SERVICE,
    PHONE_OTP_DELIVERY_SERVICE,
    MAGIC_LINK_AUTH_SERVICE,
    TOKEN_SERVICE,
    ADMIN_CREDENTIAL_SERVICE,
  ],
})
export class AuthInfrastructureModule {}

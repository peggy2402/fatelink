import type { EmailAuthService } from '@shared/contracts/email-auth.service';
import type { FacebookAuthService } from '@shared/contracts/facebook-auth.service';
import type { GoogleAuthService } from '@shared/contracts/google-auth.service';
import type { MagicLinkAuthService } from '@shared/contracts/magic-link-auth.service';
import type { PhoneAuthService } from '@shared/contracts/phone-auth.service';
import type { TokenService } from '@shared/contracts/token.service';
import { MongooseAuthSessionRepository } from '@contexts/auth/infrastructure/repositories/mongoose-auth-session.repository';
import { MongooseAuthIdentityRepository } from '@contexts/auth/infrastructure/repositories/mongoose-auth-identity.repository';
import { AuthSessionIssuer } from '@contexts/auth/application/services/auth-session-issuer.service';
import { LoginWithEmailUseCase } from '@contexts/auth/application/usecases/login-with-email.usecase';
import { LoginWithFacebookUseCase } from '@contexts/auth/application/usecases/login-with-facebook.usecase';
import { LoginWithGoogleUseCase } from '@contexts/auth/application/usecases/login-with-google.usecase';
import { LoginWithMagicLinkUseCase } from '@contexts/auth/application/usecases/login-with-magic-link.usecase';
import { LoginWithPhoneOtpUseCase } from '@contexts/auth/application/usecases/login-with-phone-otp.usecase';
import { ListAuthSessionsUseCase } from '@contexts/auth/application/usecases/list-auth-sessions.usecase';
import { LogoutUseCase } from '@contexts/auth/application/usecases/logout.usecase';
import { RefreshTokenUseCase } from '@contexts/auth/application/usecases/refresh-token.usecase';
import { RegisterWithEmailUseCase } from '@contexts/auth/application/usecases/register-with-email.usecase';
import { RevokeAuthSessionUseCase } from '@contexts/auth/application/usecases/revoke-auth-session.usecase';
import { RequestMagicLinkUseCase } from '@contexts/auth/application/usecases/request-magic-link.usecase';
import { RequestPhoneOtpUseCase } from '@contexts/auth/application/usecases/request-phone-otp.usecase';
import { ValidateAdminTokenUseCase } from '@contexts/auth/application/usecases/validate-admin-token.usecase';
import { ValidateUserTokenUseCase } from '@contexts/auth/application/usecases/validate-user-token.usecase';
import { AUTH_APPLICATION_TOKENS } from './auth.tokens';
import {
  EMAIL_AUTH_SERVICE,
  FACEBOOK_AUTH_SERVICE,
  GOOGLE_AUTH_SERVICE,
  MAGIC_LINK_AUTH_SERVICE,
  PHONE_AUTH_SERVICE,
  TOKEN_SERVICE,
  USER_REPOSITORY,
} from '@shared/kernel/injection-tokens';
import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';
import type { Provider } from '@nestjs/common';

export const authUseCaseProviders: Provider[] = [
  {
    provide: AuthSessionIssuer,
    useFactory: (
      authSessionRepository: MongooseAuthSessionRepository,
      userRepository: UserRepository,
      tokenService: TokenService,
    ) =>
      new AuthSessionIssuer(
        authSessionRepository,
        userRepository,
        tokenService,
      ),
    inject: [MongooseAuthSessionRepository, USER_REPOSITORY, TOKEN_SERVICE],
  },
  {
    provide: AUTH_APPLICATION_TOKENS.loginWithGoogle,
    useFactory: (
      googleAuthService: GoogleAuthService,
      userRepository: UserRepository,
      authIdentityRepository: MongooseAuthIdentityRepository,
      authSessionIssuer: AuthSessionIssuer,
    ) =>
      new LoginWithGoogleUseCase(
        googleAuthService,
        userRepository,
        authIdentityRepository,
        authSessionIssuer,
      ),
    inject: [
      GOOGLE_AUTH_SERVICE,
      USER_REPOSITORY,
      MongooseAuthIdentityRepository,
      AuthSessionIssuer,
    ],
  },
  {
    provide: AUTH_APPLICATION_TOKENS.registerWithEmail,
    useFactory: (
      emailAuthService: EmailAuthService,
      authSessionIssuer: AuthSessionIssuer,
    ) => new RegisterWithEmailUseCase(emailAuthService, authSessionIssuer),
    inject: [EMAIL_AUTH_SERVICE, AuthSessionIssuer],
  },
  {
    provide: AUTH_APPLICATION_TOKENS.loginWithEmail,
    useFactory: (
      emailAuthService: EmailAuthService,
      authSessionIssuer: AuthSessionIssuer,
    ) => new LoginWithEmailUseCase(emailAuthService, authSessionIssuer),
    inject: [EMAIL_AUTH_SERVICE, AuthSessionIssuer],
  },
  {
    provide: AUTH_APPLICATION_TOKENS.requestPhoneOtp,
    useFactory: (phoneAuthService: PhoneAuthService) =>
      new RequestPhoneOtpUseCase(phoneAuthService),
    inject: [PHONE_AUTH_SERVICE],
  },
  {
    provide: AUTH_APPLICATION_TOKENS.loginWithPhoneOtp,
    useFactory: (
      phoneAuthService: PhoneAuthService,
      authSessionIssuer: AuthSessionIssuer,
    ) => new LoginWithPhoneOtpUseCase(phoneAuthService, authSessionIssuer),
    inject: [PHONE_AUTH_SERVICE, AuthSessionIssuer],
  },
  {
    provide: AUTH_APPLICATION_TOKENS.requestMagicLink,
    useFactory: (magicLinkAuthService: MagicLinkAuthService) =>
      new RequestMagicLinkUseCase(magicLinkAuthService),
    inject: [MAGIC_LINK_AUTH_SERVICE],
  },
  {
    provide: AUTH_APPLICATION_TOKENS.loginWithMagicLink,
    useFactory: (
      magicLinkAuthService: MagicLinkAuthService,
      authSessionIssuer: AuthSessionIssuer,
    ) => new LoginWithMagicLinkUseCase(magicLinkAuthService, authSessionIssuer),
    inject: [MAGIC_LINK_AUTH_SERVICE, AuthSessionIssuer],
  },
  {
    provide: AUTH_APPLICATION_TOKENS.loginWithFacebook,
    useFactory: (
      facebookAuthService: FacebookAuthService,
      userRepository: UserRepository,
      authIdentityRepository: MongooseAuthIdentityRepository,
      authSessionIssuer: AuthSessionIssuer,
    ) =>
      new LoginWithFacebookUseCase(
        facebookAuthService,
        userRepository,
        authIdentityRepository,
        authSessionIssuer,
      ),
    inject: [
      FACEBOOK_AUTH_SERVICE,
      USER_REPOSITORY,
      MongooseAuthIdentityRepository,
      AuthSessionIssuer,
    ],
  },
  {
    provide: AUTH_APPLICATION_TOKENS.listAuthSessions,
    useFactory: (authSessionRepository: MongooseAuthSessionRepository) =>
      new ListAuthSessionsUseCase(authSessionRepository),
    inject: [MongooseAuthSessionRepository],
  },
  {
    provide: AUTH_APPLICATION_TOKENS.revokeAuthSession,
    useFactory: (authSessionRepository: MongooseAuthSessionRepository) =>
      new RevokeAuthSessionUseCase(authSessionRepository),
    inject: [MongooseAuthSessionRepository],
  },
  {
    provide: AUTH_APPLICATION_TOKENS.logout,
    useFactory: (authSessionRepository: MongooseAuthSessionRepository) =>
      new LogoutUseCase(authSessionRepository),
    inject: [MongooseAuthSessionRepository],
  },
  {
    provide: AUTH_APPLICATION_TOKENS.refreshToken,
    useFactory: (
      authSessionRepository: MongooseAuthSessionRepository,
      tokenService: TokenService,
      userRepository: UserRepository,
      authSessionIssuer: AuthSessionIssuer,
    ) =>
      new RefreshTokenUseCase(
        authSessionRepository,
        tokenService,
        userRepository,
        authSessionIssuer,
      ),
    inject: [
      MongooseAuthSessionRepository,
      TOKEN_SERVICE,
      USER_REPOSITORY,
      AuthSessionIssuer,
    ],
  },
  {
    provide: AUTH_APPLICATION_TOKENS.validateAdminToken,
    useFactory: (tokenService: TokenService) =>
      new ValidateAdminTokenUseCase(tokenService),
    inject: [TOKEN_SERVICE],
  },
  {
    provide: AUTH_APPLICATION_TOKENS.validateUserToken,
    useFactory: (
      authSessionRepository: MongooseAuthSessionRepository,
      tokenService: TokenService,
      userRepository: UserRepository,
    ) =>
      new ValidateUserTokenUseCase(
        authSessionRepository,
        tokenService,
        userRepository,
      ),
    inject: [MongooseAuthSessionRepository, TOKEN_SERVICE, USER_REPOSITORY],
  },
];

export const authUseCases = [
  AUTH_APPLICATION_TOKENS.loginWithGoogle,
  AUTH_APPLICATION_TOKENS.registerWithEmail,
  AUTH_APPLICATION_TOKENS.loginWithEmail,
  AUTH_APPLICATION_TOKENS.requestPhoneOtp,
  AUTH_APPLICATION_TOKENS.loginWithPhoneOtp,
  AUTH_APPLICATION_TOKENS.requestMagicLink,
  AUTH_APPLICATION_TOKENS.loginWithMagicLink,
  AUTH_APPLICATION_TOKENS.loginWithFacebook,
  AUTH_APPLICATION_TOKENS.listAuthSessions,
  AUTH_APPLICATION_TOKENS.revokeAuthSession,
  AUTH_APPLICATION_TOKENS.logout,
  AUTH_APPLICATION_TOKENS.refreshToken,
  AUTH_APPLICATION_TOKENS.validateAdminToken,
  AUTH_APPLICATION_TOKENS.validateUserToken,
];

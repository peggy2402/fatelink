import type { GoogleAuthService } from '@shared/contracts/google-auth.service';
import type { TokenService } from '@shared/contracts/token.service';
import { GoogleLoginUseCase } from '@contexts/auth/application/usecases/google-login.usecase';
import { LogoutUseCase } from '@contexts/auth/application/usecases/logout.usecase';
import { ValidateAdminTokenUseCase } from '@contexts/auth/application/usecases/validate-admin-token.usecase';
import { ValidateUserTokenUseCase } from '@contexts/auth/application/usecases/validate-user-token.usecase';
import { AUTH_APPLICATION_TOKENS } from './auth.tokens';
import {
  GOOGLE_AUTH_SERVICE,
  TOKEN_SERVICE,
  USER_REPOSITORY,
} from '@shared/kernel/injection-tokens';
import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';
import type { Provider } from '@nestjs/common';

export const authUseCaseProviders: Provider[] = [
  {
    provide: AUTH_APPLICATION_TOKENS.googleLogin,
    useFactory: (
      googleAuthService: GoogleAuthService,
      userRepository: UserRepository,
      tokenService: TokenService,
    ) =>
      new GoogleLoginUseCase(googleAuthService, userRepository, tokenService),
    inject: [GOOGLE_AUTH_SERVICE, USER_REPOSITORY, TOKEN_SERVICE],
  },
  {
    provide: AUTH_APPLICATION_TOKENS.logout,
    useFactory: (userRepository: UserRepository) =>
      new LogoutUseCase(userRepository),
    inject: [USER_REPOSITORY],
  },
  {
    provide: AUTH_APPLICATION_TOKENS.validateAdminToken,
    useFactory: (tokenService: TokenService) =>
      new ValidateAdminTokenUseCase(tokenService),
    inject: [TOKEN_SERVICE],
  },
  {
    provide: AUTH_APPLICATION_TOKENS.validateUserToken,
    useFactory: (tokenService: TokenService, userRepository: UserRepository) =>
      new ValidateUserTokenUseCase(tokenService, userRepository),
    inject: [TOKEN_SERVICE, USER_REPOSITORY],
  },
];

export const authUseCases = [
  AUTH_APPLICATION_TOKENS.googleLogin,
  AUTH_APPLICATION_TOKENS.logout,
  AUTH_APPLICATION_TOKENS.validateAdminToken,
  AUTH_APPLICATION_TOKENS.validateUserToken,
];

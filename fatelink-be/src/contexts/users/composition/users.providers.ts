import { FindEmotionMatchesUseCase } from '@contexts/users/application/usecases/find-emotion-matches.usecase';
import { GetUserProfileUseCase } from '@contexts/users/application/usecases/get-user-profile.usecase';
import { UpdateFcmTokenUseCase } from '@contexts/users/application/usecases/update-fcm-token.usecase';
import { UpdateUserTraitsUseCase } from '@contexts/users/application/usecases/update-user-traits.usecase';
import { USERS_APPLICATION_TOKENS } from './users.tokens';
import { USER_REPOSITORY } from '@shared/kernel/injection-tokens';
import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';
import type { Provider } from '@nestjs/common';

export const usersUseCaseProviders: Provider[] = [
  {
    provide: USERS_APPLICATION_TOKENS.findEmotionMatches,
    useFactory: (userRepository: UserRepository) =>
      new FindEmotionMatchesUseCase(userRepository),
    inject: [USER_REPOSITORY],
  },
  {
    provide: USERS_APPLICATION_TOKENS.getUserProfile,
    useFactory: (userRepository: UserRepository) =>
      new GetUserProfileUseCase(userRepository),
    inject: [USER_REPOSITORY],
  },
  {
    provide: USERS_APPLICATION_TOKENS.updateFcmToken,
    useFactory: (userRepository: UserRepository) =>
      new UpdateFcmTokenUseCase(userRepository),
    inject: [USER_REPOSITORY],
  },
  {
    provide: USERS_APPLICATION_TOKENS.updateUserTraits,
    useFactory: (userRepository: UserRepository) =>
      new UpdateUserTraitsUseCase(userRepository),
    inject: [USER_REPOSITORY],
  },
];

export const usersUseCases = [
  USERS_APPLICATION_TOKENS.findEmotionMatches,
  USERS_APPLICATION_TOKENS.getUserProfile,
  USERS_APPLICATION_TOKENS.updateFcmToken,
  USERS_APPLICATION_TOKENS.updateUserTraits,
];

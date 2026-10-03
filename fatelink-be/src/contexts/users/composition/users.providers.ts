import { FindEmotionMatchesUseCase } from '@contexts/users/application/usecases/find-emotion-matches.usecase';
import { GetUserProfileUseCase } from '@contexts/users/application/usecases/get-user-profile.usecase';
import { UpdateFcmTokenUseCase } from '@contexts/users/application/usecases/update-fcm-token.usecase';
import { UpdateUserTraitsUseCase } from '@contexts/users/application/usecases/update-user-traits.usecase';
import { USERS_APPLICATION_TOKENS } from './users.tokens';
import { USER_REPOSITORY } from '@shared/kernel/injection-tokens';
import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';
import type { Provider } from '@nestjs/common';

import { UpdateUserFrequencyUseCase } from '@contexts/users/application/usecases/update-user-frequency.usecase';
import { UpdateUserProfileUseCase } from '@contexts/users/application/usecases/update-user-profile.usecase';
import { RecordProfileViewUseCase } from '@contexts/users/application/usecases/record-profile-view.usecase';
import { ToggleUserLikeUseCase } from '@contexts/users/application/usecases/toggle-user-like.usecase';
import { RecordWaveUseCase } from '@contexts/users/application/usecases/record-wave.usecase';
import { GetNotificationsUseCase } from '@contexts/users/application/usecases/get-notifications.usecase';
import { MarkNotificationReadUseCase } from '@contexts/users/application/usecases/mark-notification-read.usecase';

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
  {
    provide: USERS_APPLICATION_TOKENS.updateUserFrequency,
    useFactory: (userRepository: UserRepository) =>
      new UpdateUserFrequencyUseCase(userRepository),
    inject: [USER_REPOSITORY],
  },
  {
    provide: USERS_APPLICATION_TOKENS.updateUserProfile,
    useFactory: (userRepository: UserRepository) =>
      new UpdateUserProfileUseCase(userRepository),
    inject: [USER_REPOSITORY],
  },
  {
    provide: USERS_APPLICATION_TOKENS.recordProfileView,
    useFactory: (userRepository: UserRepository) =>
      new RecordProfileViewUseCase(userRepository),
    inject: [USER_REPOSITORY],
  },
  {
    provide: USERS_APPLICATION_TOKENS.toggleUserLike,
    useFactory: (userRepository: UserRepository) =>
      new ToggleUserLikeUseCase(userRepository),
    inject: [USER_REPOSITORY],
  },
  {
    provide: USERS_APPLICATION_TOKENS.recordWave,
    useFactory: (userRepository: UserRepository) =>
      new RecordWaveUseCase(userRepository),
    inject: [USER_REPOSITORY],
  },
  {
    provide: USERS_APPLICATION_TOKENS.getNotifications,
    useFactory: (userRepository: UserRepository) =>
      new GetNotificationsUseCase(userRepository),
    inject: [USER_REPOSITORY],
  },
  {
    provide: USERS_APPLICATION_TOKENS.markNotificationRead,
    useFactory: (userRepository: UserRepository) =>
      new MarkNotificationReadUseCase(userRepository),
    inject: [USER_REPOSITORY],
  },
];

export const usersUseCases = [
  USERS_APPLICATION_TOKENS.findEmotionMatches,
  USERS_APPLICATION_TOKENS.getUserProfile,
  USERS_APPLICATION_TOKENS.updateFcmToken,
  USERS_APPLICATION_TOKENS.updateUserTraits,
  USERS_APPLICATION_TOKENS.updateUserFrequency,
  USERS_APPLICATION_TOKENS.updateUserProfile,
  USERS_APPLICATION_TOKENS.recordProfileView,
  USERS_APPLICATION_TOKENS.toggleUserLike,
  USERS_APPLICATION_TOKENS.recordWave,
  USERS_APPLICATION_TOKENS.getNotifications,
  USERS_APPLICATION_TOKENS.markNotificationRead,
];

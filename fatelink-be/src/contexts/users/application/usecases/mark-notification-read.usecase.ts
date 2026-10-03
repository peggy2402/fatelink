import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';

export class MarkNotificationReadUseCase {
  constructor(private readonly userRepository: UserRepository) {}

  execute(input: {
    userId: string;
    notificationId?: string;
    markAll?: boolean;
  }) {
    if (input.markAll) {
      return this.userRepository.markAllNotificationsAsRead(input.userId);
    }
    if (input.notificationId) {
      return this.userRepository.markNotificationAsRead(
        input.userId,
        input.notificationId,
      );
    }
    return Promise.resolve(false);
  }
}

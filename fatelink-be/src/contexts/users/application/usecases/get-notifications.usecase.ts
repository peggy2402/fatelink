import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';

export class GetNotificationsUseCase {
  constructor(private readonly userRepository: UserRepository) {}

  execute(input: { userId: string }) {
    return this.userRepository.getNotifications(input.userId);
  }
}

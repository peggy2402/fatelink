import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';

export class UpdateFcmTokenUseCase {
  constructor(private readonly userRepository: UserRepository) {}

  execute(input: { userId: string; fcmToken: string }) {
    return this.userRepository.updateFcmToken(input.userId, input.fcmToken);
  }
}

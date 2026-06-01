import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';

export class AdminBanUserUseCase {
  constructor(private readonly userRepository: UserRepository) {}

  execute(input: { userId: string; isBanned: boolean }) {
    return this.userRepository.banUser(input.userId, input.isBanned);
  }
}

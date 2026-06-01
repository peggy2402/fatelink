import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';

export class GetUserProfileUseCase {
  constructor(private readonly userRepository: UserRepository) {}

  execute(input: { userId: string }) {
    return this.userRepository.findById(input.userId);
  }
}

import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';

export class FindEmotionMatchesUseCase {
  constructor(private readonly userRepository: UserRepository) {}

  execute(input: { userId: string }) {
    return this.userRepository.findMatches(input.userId);
  }
}

import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';

export class ToggleUserLikeUseCase {
  constructor(private readonly userRepository: UserRepository) {}

  execute(input: { targetUserId: string; likerId: string }) {
    return this.userRepository.toggleLike(input.targetUserId, input.likerId);
  }
}

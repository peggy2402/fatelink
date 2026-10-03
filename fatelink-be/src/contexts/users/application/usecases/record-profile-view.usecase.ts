import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';

export class RecordProfileViewUseCase {
  constructor(private readonly userRepository: UserRepository) {}

  execute(input: { targetUserId: string; viewerId: string }) {
    return this.userRepository.recordProfileView(
      input.targetUserId,
      input.viewerId,
    );
  }
}

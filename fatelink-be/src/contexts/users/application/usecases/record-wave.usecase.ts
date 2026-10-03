import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';

export class RecordWaveUseCase {
  constructor(private readonly userRepository: UserRepository) {}

  execute(input: { targetUserId: string; senderId: string }) {
    return this.userRepository.recordWave(input.targetUserId, input.senderId);
  }
}

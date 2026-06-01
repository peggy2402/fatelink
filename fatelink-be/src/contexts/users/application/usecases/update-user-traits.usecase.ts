import type {
  UpdateUserTraitsCommand,
  UpdateUserTraitsHandler,
} from '@contexts/users/application/contracts/update-user-traits.contract';
import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';

export class UpdateUserTraitsUseCase implements UpdateUserTraitsHandler {
  constructor(private readonly userRepository: UserRepository) {}

  async execute(input: UpdateUserTraitsCommand) {
    const user = await this.userRepository.findById(input.userId);
    if (!user) {
      return;
    }

    const updatedTraits = user.applyTraitsUpdate({
      emotions: input.emotions,
      personality: input.personality,
      latestEmotion: input.latestEmotion,
    });

    await this.userRepository.updateTraits(
      input.userId,
      updatedTraits.emotions,
      updatedTraits.personality,
      updatedTraits.latestEmotion,
    );
  }
}

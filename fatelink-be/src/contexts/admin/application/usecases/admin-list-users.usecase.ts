import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';

export class AdminListUsersUseCase {
  constructor(private readonly userRepository: UserRepository) {}

  execute() {
    return this.userRepository.findAll();
  }
}

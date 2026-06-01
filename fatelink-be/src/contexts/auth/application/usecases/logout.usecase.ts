import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';

export class LogoutUseCase {
  constructor(private readonly userRepository: UserRepository) {}

  async execute(input: { userId: string }) {
    await this.userRepository.incrementTokenVersion(input.userId);
    return { message: 'Đăng xuất thành công, token đã bị thu hồi.' };
  }
}

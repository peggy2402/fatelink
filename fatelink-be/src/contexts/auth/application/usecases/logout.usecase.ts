import type { AuthSessionRepository } from '@contexts/auth/domain/repositories/auth-session.repository';

export class LogoutUseCase {
  constructor(private readonly authSessionRepository: AuthSessionRepository) {}

  async execute(input: { sessionId: string }) {
    await this.authSessionRepository.revokeBySessionId(
      input.sessionId,
      'logout',
    );
    return { message: 'Đăng xuất thành công, token đã bị thu hồi.' };
  }
}

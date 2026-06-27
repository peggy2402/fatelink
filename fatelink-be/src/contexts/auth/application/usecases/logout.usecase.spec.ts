import { LogoutUseCase } from './logout.usecase';

describe('LogoutUseCase', () => {
  it('revokes the current session with a logout reason', async () => {
    const authSessionRepository = {
      revokeBySessionId: jest.fn().mockResolvedValue(undefined),
    };
    const useCase = new LogoutUseCase(authSessionRepository as never);

    const result = await useCase.execute({ sessionId: 'session-1' });

    expect(authSessionRepository.revokeBySessionId).toHaveBeenCalledWith(
      'session-1',
      'logout',
    );
    expect(result).toEqual({
      message: 'Đăng xuất thành công, token đã bị thu hồi.',
    });
  });
});

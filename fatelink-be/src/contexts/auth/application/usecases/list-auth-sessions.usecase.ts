import type { AuthSessionRepository } from '@contexts/auth/domain/repositories/auth-session.repository';

export class ListAuthSessionsUseCase {
  constructor(private readonly authSessionRepository: AuthSessionRepository) {}

  async execute(input: { userId: string; currentSessionId?: string }) {
    const sessions = await this.authSessionRepository.findByUserId(
      input.userId,
    );

    return sessions.map((session) => ({
      sessionId: session.sessionId,
      userId: session.userId,
      deviceType: session.deviceType,
      deviceId: session.deviceId,
      status: session.status,
      ipAddress: session.ipAddress,
      userAgent: session.userAgent,
      createdAt: session.createdAt,
      lastRefreshedAt: session.lastRefreshedAt,
      lastSeenAt: session.lastSeenAt,
      revokedAt: session.revokedAt,
      revokedReason: session.revokedReason,
      replacedBySessionId: session.replacedBySessionId,
      current: session.sessionId === input.currentSessionId,
    }));
  }
}

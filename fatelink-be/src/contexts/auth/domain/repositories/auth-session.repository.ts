export const AUTH_SESSION_STATUS = {
  ACTIVE: 'active',
  ROTATED: 'rotated',
  REVOKED: 'revoked',
} as const;

export type AuthSessionStatus =
  (typeof AUTH_SESSION_STATUS)[keyof typeof AUTH_SESSION_STATUS];

export interface AuthSessionRecord {
  sessionId: string;
  userId: string;
  deviceType: string;
  deviceId: string;
  refreshTokenId: string;
  status: AuthSessionStatus;
  ipAddress?: string;
  userAgent?: string;
  createdAt: Date;
  lastRefreshedAt: Date;
  lastSeenAt: Date;
  revokedAt?: Date;
  revokedReason?: string;
  replacedBySessionId?: string;
}

export interface AuthSessionRepository {
  create(input: {
    sessionId: string;
    userId: string;
    deviceType: string;
    deviceId: string;
    refreshTokenId: string;
    ipAddress?: string;
    userAgent?: string;
  }): Promise<AuthSessionRecord>;
  findActiveBySessionId(sessionId: string): Promise<AuthSessionRecord | null>;
  findBySessionId(sessionId: string): Promise<AuthSessionRecord | null>;
  findByUserId(userId: string): Promise<AuthSessionRecord[]>;
  rotate(input: {
    currentSessionId: string;
    currentRefreshTokenId: string;
    nextRefreshTokenId: string;
    deviceType: string;
    deviceId: string;
    ipAddress?: string;
    userAgent?: string;
  }): Promise<AuthSessionRecord | null>;
  touch(sessionId: string): Promise<void>;
  revokeBySessionId(sessionId: string, reason?: string): Promise<void>;
}

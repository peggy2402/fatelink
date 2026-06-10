export interface AccessTokenPayload {
  sub: string;
  email?: string;
  deviceType?: string;
  deviceId?: string;
  sessionId?: string;
  role?: string;
}

export interface RefreshTokenPayload {
  sub: string;
  email?: string;
  deviceType?: string;
  deviceId: string;
  sessionId: string;
  jti: string;
}

export interface TokenService {
  signAccessToken(payload: AccessTokenPayload): string;
  verifyAccessToken(token: string): Promise<AccessTokenPayload>;
  signRefreshToken(payload: RefreshTokenPayload): string;
  verifyRefreshToken(token: string): Promise<RefreshTokenPayload>;
}

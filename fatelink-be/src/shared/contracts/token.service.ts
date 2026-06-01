export interface AccessTokenPayload {
  sub: string;
  email?: string;
  tokenVersion?: number;
  role?: string;
}

export interface TokenService {
  signAccessToken(payload: AccessTokenPayload): string;
  verifyAccessToken(token: string): Promise<AccessTokenPayload>;
}

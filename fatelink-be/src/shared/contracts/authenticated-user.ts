export interface AuthenticatedUser {
  sub: string;
  email?: string;
  deviceType?: string;
  deviceId?: string;
  sessionId?: string;
  role?: string;
}

export interface AuthenticatedUser {
  sub: string;
  email?: string;
  tokenVersion?: number;
  role?: string;
}

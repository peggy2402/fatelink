export interface GoogleUserProfile {
  email: string;
  name?: string;
  avatar?: string;
  googleId: string;
}

export interface GoogleAuthService {
  verifyIdToken(token: string): Promise<GoogleUserProfile>;
}

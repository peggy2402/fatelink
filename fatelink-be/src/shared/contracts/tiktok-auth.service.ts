export interface TikTokUserProfile {
  email?: string;
  name?: string;
  avatar?: string;
  tikTokId: string;
}

export interface TikTokAuthService {
  exchangeAuthorizationCode(input: {
    code: string;
    codeVerifier: string;
  }): Promise<{ accessToken: string }>;
  authenticate(input: { accessToken: string }): Promise<TikTokUserProfile>;
}

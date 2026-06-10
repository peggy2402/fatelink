export interface FacebookUserProfile {
  email: string;
  name?: string;
  avatar?: string;
  facebookId: string;
}

export interface FacebookAuthService {
  authenticate(input: { accessToken: string }): Promise<FacebookUserProfile>;
}

export interface ZaloUserProfile {
  email?: string;
  name?: string;
  avatar?: string;
  zaloId: string;
}

export interface ZaloAuthService {
  authenticate(input: { accessToken: string }): Promise<ZaloUserProfile>;
}

export type AuthProvider = 'email' | 'facebook' | 'phone' | 'google';

export interface AuthIdentityRecord {
  userId: string;
  provider: AuthProvider;
  providerUserId: string;
  providerEmail?: string;
  secretHash?: string;
}

export interface AuthIdentityRepository {
  findByProvider(
    provider: AuthProvider,
    providerUserId: string,
  ): Promise<AuthIdentityRecord | null>;
  upsertEmailCredential(input: {
    userId: string;
    email: string;
    passwordHash: string;
  }): Promise<AuthIdentityRecord>;
  linkFacebookIdentity(input: {
    userId: string;
    facebookId: string;
    email?: string;
  }): Promise<AuthIdentityRecord>;
  linkGoogleIdentity(input: {
    userId: string;
    googleId: string;
    email?: string;
  }): Promise<AuthIdentityRecord>;
  linkPhoneIdentity(input: {
    userId: string;
    phoneNumber: string;
  }): Promise<AuthIdentityRecord>;
}

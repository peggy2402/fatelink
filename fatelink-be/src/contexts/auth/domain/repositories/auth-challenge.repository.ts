export interface AuthChallengeRecord {
  type: 'phone_otp' | 'magic_link';
  key: string;
  secretHash: string;
  expiresAt: Date;
  attemptCount?: number;
  maxAttempts?: number;
  lockedAt?: Date;
  metadata?: Record<string, string>;
}

export interface AuthChallengeRepository {
  save(input: AuthChallengeRecord): Promise<AuthChallengeRecord>;
  find(
    type: AuthChallengeRecord['type'],
    key: string,
  ): Promise<AuthChallengeRecord | null>;
  consumeMagicLink(
    key: string,
    tokenDigest: string,
  ): Promise<AuthChallengeRecord | null>;
  registerFailedAttempt(
    type: AuthChallengeRecord['type'],
    key: string,
  ): Promise<AuthChallengeRecord | null>;
  consume(type: AuthChallengeRecord['type'], key: string): Promise<void>;
}

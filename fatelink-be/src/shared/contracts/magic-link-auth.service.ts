import type { User } from '@contexts/users/domain/entities/user';

export interface MagicLinkAuthService {
  requestLink(input: { email: string; name?: string }): Promise<{
    message: string;
    magicLink?: string;
    expiresAt: Date;
  }>;
  authenticate(input: { token: string }): Promise<User>;
}

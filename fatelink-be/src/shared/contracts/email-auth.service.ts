import type { User } from '@contexts/users/domain/entities/user';

export interface EmailAuthService {
  register(input: {
    email: string;
    password: string;
    name?: string;
  }): Promise<User>;
  authenticate(input: { email: string; password: string }): Promise<User>;
}

import type { AdminCredentialService } from '@shared/contracts/admin-credential.service';

export class EnvAdminCredentialServiceImpl implements AdminCredentialService {
  validate(username: string, password: string): boolean {
    return (
      username === process.env.ADMIN_USERNAME &&
      password === process.env.ADMIN_PASSWORD
    );
  }
}

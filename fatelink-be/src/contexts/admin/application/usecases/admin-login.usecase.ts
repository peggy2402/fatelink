import type { AdminCredentialService } from '@shared/contracts/admin-credential.service';
import type { TokenService } from '@shared/contracts/token.service';
import { UnauthorizedApplicationError } from '@shared/errors/application-error';

export class AdminLoginUseCase {
  constructor(
    private readonly credentials: AdminCredentialService,
    private readonly tokenService: TokenService,
  ) {}

  execute(input: { username: string; password: string }) {
    if (!this.credentials.validate(input.username, input.password)) {
      throw new UnauthorizedApplicationError(
        'Sai tài khoản hoặc mật khẩu quản trị viên!',
      );
    }

    return {
      accessToken: this.tokenService.signAccessToken({
        sub: input.username,
        role: 'admin',
      }),
      role: 'admin',
    };
  }
}

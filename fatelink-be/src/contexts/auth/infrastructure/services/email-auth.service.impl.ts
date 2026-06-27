import type { EmailAuthService } from '@shared/contracts/email-auth.service';
import type { AuthIdentityRepository } from '@contexts/auth/domain/repositories/auth-identity.repository';
import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';
import {
  ConflictApplicationError,
  UnauthorizedApplicationError,
} from '@shared/errors/application-error';
import { ERROR_CODES } from '@shared/errors/error-codes';
import type { SecretHashService } from './secret-hash.service';

export class EmailAuthServiceImpl implements EmailAuthService {
  constructor(
    private readonly userRepository: UserRepository,
    private readonly authIdentityRepository: AuthIdentityRepository,
    private readonly secretHashService: SecretHashService,
  ) {}

  async register(input: { email: string; password: string; name?: string }) {
    const existingUser = await this.userRepository.findByEmail(input.email);

    const existingIdentity = await this.authIdentityRepository.findByProvider(
      'email',
      input.email,
    );

    if (existingIdentity?.secretHash) {
      throw new ConflictApplicationError(
        'Email này đã được đăng ký.',
        ERROR_CODES.AUTH_EMAIL_ALREADY_REGISTERED,
      );
    }

    if (existingUser?.id) {
      throw new ConflictApplicationError(
        'Email này đã thuộc một tài khoản hiện có. Cần xác minh quyền sở hữu email trước khi thiết lập mật khẩu.',
        ERROR_CODES.AUTH_EMAIL_REGISTRATION_REQUIRES_VERIFICATION,
      );
    }

    const passwordHash = this.secretHashService.hash(input.password);

    const createdUser = await this.userRepository.createProfileAccount({
      email: input.email,
      name: input.name || input.email.split('@')[0],
      avatar: '',
    });
    await this.authIdentityRepository.upsertEmailCredential({
      userId: createdUser.id || '',
      email: input.email,
      passwordHash,
    });
    return createdUser;
  }

  async authenticate(input: { email: string; password: string }) {
    const identity = await this.authIdentityRepository.findByProvider(
      'email',
      input.email,
    );

    if (
      !identity?.secretHash ||
      !this.secretHashService.verify(input.password, identity.secretHash)
    ) {
      throw new UnauthorizedApplicationError(
        'Email hoặc mật khẩu không đúng.',
        ERROR_CODES.AUTH_INVALID_EMAIL_CREDENTIALS,
      );
    }

    const user = await this.userRepository.findById(identity.userId);
    if (!user) {
      throw new UnauthorizedApplicationError(
        'Tài khoản email không còn tồn tại.',
        ERROR_CODES.AUTH_EMAIL_ACCOUNT_NOT_FOUND,
      );
    }

    return user;
  }
}

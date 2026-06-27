import type { ConfigService } from '@nestjs/config';
import { createHash, randomBytes } from 'crypto';
import type { AuthChallengeRepository } from '@contexts/auth/domain/repositories/auth-challenge.repository';
import type { MagicLinkAuthService } from '@shared/contracts/magic-link-auth.service';
import type { EmailDeliveryService } from '@shared/contracts/email-delivery.service';
import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';
import {
  BadRequestApplicationError,
  UnauthorizedApplicationError,
} from '@shared/errors/application-error';
import { AUTH_ENV } from '@contexts/auth/infrastructure/config/auth-env';
import { ERROR_CODES } from '@shared/errors/error-codes';
import type { SecretHashService } from './secret-hash.service';

export class MagicLinkAuthServiceImpl implements MagicLinkAuthService {
  constructor(
    private readonly userRepository: UserRepository,
    private readonly authChallengeRepository: AuthChallengeRepository,
    private readonly configService: ConfigService,
    private readonly secretHashService: SecretHashService,
    // TODO: Tách việc gửi email ra module/context riêng (communication/notification),
    // auth chỉ nên yêu cầu "gửi magic link" thay vì giữ hạ tầng email ở đây.
    private readonly emailDeliveryService: EmailDeliveryService,
  ) {}

  async requestLink(input: { email: string; name?: string }) {
    const tokenSecret = randomBytes(24).toString('hex');
    const expiresAt = new Date(Date.now() + this.getExpiryMinutes() * 60000);

    await this.authChallengeRepository.save({
      type: 'magic_link',
      key: input.email,
      secretHash: this.secretHashService.hash(tokenSecret),
      expiresAt,
      metadata: {
        ...(input.name ? { name: input.name } : {}),
        tokenDigest: this.digestToken(tokenSecret),
      },
    });

    const token = `${encodeURIComponent(input.email)}.${tokenSecret}`;
    const baseUrl =
      this.configService.get<string>(AUTH_ENV.magicLinkBaseUrl) ||
      'http://localhost:3000/magic-link';
    const magicLink = `${baseUrl}?token=${encodeURIComponent(token)}`;

    if (!this.shouldExposeChallenge()) {
      await this.emailDeliveryService.sendMagicLink({
        to: input.email,
        subject: 'Fatelink magic link đăng nhập',
        magicLink,
        expiresAt,
        name: input.name,
      });
    }

    return {
      message: 'Magic link đã được tạo.',
      magicLink: this.shouldExposeChallenge() ? magicLink : undefined,
      expiresAt,
    };
  }

  async authenticate(input: { token: string }) {
    const token = input.token;
    const payload = this.parseTokenPayload(token);
    const challenge = await this.authChallengeRepository.consumeMagicLink(
      payload.email,
      this.digestToken(payload.token),
    );

    if (!challenge) {
      throw new UnauthorizedApplicationError(
        'Magic link không hợp lệ hoặc đã hết hạn.',
        ERROR_CODES.AUTH_MAGIC_LINK_INVALID,
      );
    }
    const existingUser = await this.userRepository.findByEmail(payload.email);
    if (existingUser) {
      return existingUser;
    }

    return this.userRepository.createProfileAccount({
      email: payload.email,
      name: challenge.metadata?.name || payload.email.split('@')[0],
      avatar: '',
    });
  }

  private parseTokenPayload(rawToken: string) {
    const separatorIndex = rawToken.lastIndexOf('.');
    if (separatorIndex <= 0 || separatorIndex === rawToken.length - 1) {
      throw new BadRequestApplicationError(
        'Magic link token không đúng định dạng.',
        ERROR_CODES.AUTH_MAGIC_LINK_MALFORMED,
      );
    }
    return {
      email: decodeURIComponent(rawToken.slice(0, separatorIndex)),
      token: rawToken.slice(separatorIndex + 1),
    };
  }

  private getExpiryMinutes() {
    return Number(
      this.configService.get<string>(AUTH_ENV.magicLinkExpiresInMinutes) ||
        '15',
    );
  }

  private shouldExposeChallenge() {
    return (
      (this.configService.get<string>(AUTH_ENV.authExposeDebugChallenges) ||
        'false') === 'true'
    );
  }

  private digestToken(token: string) {
    return createHash('sha256').update(token).digest('hex');
  }
}

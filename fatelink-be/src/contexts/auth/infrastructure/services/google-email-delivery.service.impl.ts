import { AUTH_ENV } from '@contexts/auth/infrastructure/config/auth-env';
import type { ConfigService } from '@nestjs/config';
import nodemailer from 'nodemailer';
import type { EmailDeliveryService } from '@shared/contracts/email-delivery.service';
import { InternalApplicationError } from '@shared/errors/application-error';
import { ERROR_CODES } from '@shared/errors/error-codes';

export class GoogleEmailDeliveryServiceImpl implements EmailDeliveryService {
  // TODO: Chuyển service này ra phần riêng cho email/communication khi hoàn thiện kiến trúc.
  constructor(private readonly configService: ConfigService) {}

  async sendMagicLink(input: {
    to: string;
    subject: string;
    magicLink: string;
    expiresAt: Date;
    name?: string;
  }): Promise<void> {
    const user = this.configService.getOrThrow<string>(AUTH_ENV.gmailSmtpUser);
    const pass = this.configService.getOrThrow<string>(
      AUTH_ENV.gmailSmtpAppPassword,
    );
    const host =
      this.configService.get<string>(AUTH_ENV.gmailSmtpHost) ||
      'smtp.gmail.com';
    const port = Number(
      this.configService.get<string>(AUTH_ENV.gmailSmtpPort) || '465',
    );
    const from =
      this.configService.get<string>(AUTH_ENV.emailFromAddress) || user;

    const transporter = nodemailer.createTransport({
      host,
      port,
      secure: port === 465,
      auth: { user, pass },
    });

    try {
      await transporter.sendMail({
        from,
        to: input.to,
        subject: input.subject,
        text: this.buildText(input),
        html: this.buildHtml(input),
      });
    } catch {
      throw new InternalApplicationError(
        'Không thể gửi email magic link qua Gmail.',
        ERROR_CODES.COMMON_INTERNAL_ERROR,
      );
    }
  }

  private buildText(input: {
    magicLink: string;
    expiresAt: Date;
    name?: string;
  }) {
    const greeting = input.name ? `Chao ${input.name},` : 'Chao ban,';
    return `${greeting}\n\nNhan vao lien ket sau de dang nhap:\n${input.magicLink}\n\nLien ket het han luc: ${input.expiresAt.toISOString()}`;
  }

  private buildHtml(input: {
    magicLink: string;
    expiresAt: Date;
    name?: string;
  }) {
    const greeting = input.name ? `Chào ${input.name},` : 'Chào bạn,';
    return `<p>${greeting}</p><p>Nhấn vào liên kết sau để đăng nhập:</p><p><a href="${input.magicLink}">${input.magicLink}</a></p><p>Liên kết hết hạn lúc: ${input.expiresAt.toISOString()}</p>`;
  }
}

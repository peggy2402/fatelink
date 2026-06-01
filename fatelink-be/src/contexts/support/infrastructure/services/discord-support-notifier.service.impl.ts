import type { SupportNotifierService } from '@shared/contracts/support-notifier.service';
import type { SupportRequest } from '@contexts/support/application/contracts/support.request';

export class DiscordSupportNotifierServiceImpl implements SupportNotifierService {
  async submit(request: SupportRequest): Promise<void> {
    const webhookUrl = process.env.DISCORD_SUPPORT_WEBHOOK_URL;

    if (!webhookUrl) {
      return;
    }

    const content = [
      '**Yeu cau ho tro moi**',
      `- Ten: ${request.name}`,
      `- Email: ${request.email}`,
      `- Noi dung: ${request.content}`,
    ].join('\n');

    await fetch(webhookUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ content }),
    });
  }
}

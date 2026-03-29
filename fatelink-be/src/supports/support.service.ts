import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CreateSupportDto } from './dto/create-support.dto';

@Injectable()
export class SupportService {
  constructor(private readonly configService: ConfigService) {}

  async submitSupport(body: CreateSupportDto) {
    const webhookUrl = this.configService.get<string>('DISCORD_WEBHOOKS_CLIENT');
    
    if (!webhookUrl) {
      console.error('Lỗi: Chưa cấu hình DISCORD_WEBHOOKS_CLIENT trong .env');
      throw new HttpException('Lỗi cấu hình server', HttpStatus.INTERNAL_SERVER_ERROR);
    }

    // Tạo payload Embed định dạng siêu đẹp cho Discord
    const discordPayload = {
      username: "FateLink Support Bot",
      avatar_url: "https://cdn.phototourl.com/free/2026-03-29-184da892-ad88-4edd-8767-22a3c5ad5aa7.png", // Link logo FateLink
      embeds: [
        {
          title: "🚨 Yêu Cầu Hỗ Trợ Mới",
          color: 12390730, // Màu HEX #BD114A chuyển sang Decimal
          fields: [
            { name: "👤 Người gửi", value: `**${body.name}**`, inline: true },
            { name: "📧 Email", value: `||${body.email}||`, inline: true },
            { name: "📝 Nội dung", value: "```" + body.content + "```" }
          ],
          timestamp: new Date().toISOString(),
          footer: {
            text: "FateLink System"
          }
        }
      ]
    };

    try {
      const response = await fetch(webhookUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(discordPayload),
      });

      if (!response.ok) {
        throw new Error(`Discord API phản hồi lỗi: ${response.status}`);
      }

      return { message: 'Đã gửi yêu cầu hỗ trợ thành công' };
    } catch (error) {
      console.error('Lỗi khi bắn webhook Discord:', error);
      throw new HttpException('Không thể gửi yêu cầu vào lúc này', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }
}
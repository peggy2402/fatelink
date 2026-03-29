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
      avatar_url: "https://sf-static.upanhlaylink.com/img/image_202603298e99ebdf10483bb3c86e2be28ef92788.jpg", // Bạn có thể thay bằng link ảnh logo thực tế
      embeds: [
        {
          title: "🚨 Yêu Cầu Hỗ Trợ Mới",
          color: 12390730, // Màu HEX #BD114A chuyển sang Decimal
          fields: [
            { name: "👤 Họ và tên", value: body.name || "Không có", inline: true },
            { name: "📧 Email", value: body.email || "Không có", inline: true },
            { name: "📝 Nội dung cần hỗ trợ", value: body.content || "Không có" }
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
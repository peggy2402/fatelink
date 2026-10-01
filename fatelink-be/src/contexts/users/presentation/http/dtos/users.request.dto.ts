import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class UpdateFcmTokenDto {
  @ApiProperty({
    example: 'fcm-device-token',
    description: 'FCM token hien tai cua thiet bi',
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(2048)
  fcmToken!: string;
}

export class UpdateFrequencyDto {
  @ApiProperty({
    example: '🌧️ Chùng xuống, cần tĩnh lặng',
    description: 'Tâm trạng / Cảm xúc hiện tại của người dùng',
  })
  @IsString()
  @IsNotEmpty()
  mood!: string;

  @ApiProperty({
    example: '👂 Người biết lắng nghe',
    description: 'Nhu cầu kết nối / Kiểu người muốn gặp',
  })
  @IsString()
  @IsNotEmpty()
  vibe!: string;

  @ApiProperty({
    example: '🎧 Nhạc Indie & Lofi',
    description: 'Tín hiệu năng lượng / Gu sở thích',
  })
  @IsString()
  @IsNotEmpty()
  signal!: string;

  @ApiProperty({
    required: false,
    example: '528 Hz',
    description: 'Tần số năng lượng (Hz)',
  })
  @IsString()
  frequencyHertz?: string;
}

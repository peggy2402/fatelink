import { ApiProperty } from '@nestjs/swagger';
import {
  IsArray,
  IsBoolean,
  IsDateString,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

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

export class VibePhotoDto {
  @ApiProperty({ example: 'vibe_1727870000000_123', description: 'ID duy nhất của ảnh Vibe' })
  @IsString()
  @IsNotEmpty()
  id!: string;

  @ApiProperty({ example: 'https://...', description: 'URL hoặc Base64 ảnh Vibe' })
  @IsString()
  @IsNotEmpty()
  imageUrl!: string;

  @ApiProperty({ required: false, example: '2026-10-03T08:00:00.000Z' })
  @IsOptional()
  @IsDateString()
  createdAt?: string;

  @ApiProperty({ required: false, example: 1440, description: 'Thời hạn lưu trữ tính bằng phút (15, 60, 480, 1440, 10080, 43200)' })
  @IsOptional()
  @IsNumber()
  durationMinutes?: number;

  @ApiProperty({ example: '2026-10-04T08:00:00.000Z', description: 'Thời điểm ảnh tự động hủy' })
  @IsDateString()
  @IsNotEmpty()
  expiresAt!: string;
}

export class UpdateUserProfileDto {
  @ApiProperty({ required: false, example: 'Alex Vũ' })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  name?: string;

  @ApiProperty({ required: false, example: '@alexvu' })
  @IsOptional()
  @IsString()
  @MaxLength(30)
  handle?: string;

  @ApiProperty({ required: false, example: 'https://...' })
  @IsOptional()
  @IsString()
  avatar?: string;

  @ApiProperty({
    required: false,
    example: 'Đang tìm kiếm một kết nối định mệnh...',
    description: 'Châm ngôn sống (Tagline / Bio) - Tối đa 100 ký tự',
    maxLength: 100,
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  bio?: string;

  @ApiProperty({ required: false, example: 'female', enum: ['female', 'male', 'other'] })
  @IsOptional()
  @IsEnum(['female', 'male', 'other'])
  gender?: string;

  @ApiProperty({ required: false, example: '15/05/2000 (24 tuổi • Kim Ngưu)' })
  @IsOptional()
  @IsString()
  dateOfBirth?: string;

  @ApiProperty({ required: false, example: 'Hà Nội' })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiProperty({ required: false, example: false, description: 'Công tắc khóa diện mạo cá nhân' })
  @IsOptional()
  @IsBoolean()
  isFaceLocked?: boolean;

  @ApiProperty({ required: false, type: [VibePhotoDto], description: 'Danh sách ảnh Góc tâm hồn có thời hạn' })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => VibePhotoDto)
  vibePhotos?: VibePhotoDto[];
}

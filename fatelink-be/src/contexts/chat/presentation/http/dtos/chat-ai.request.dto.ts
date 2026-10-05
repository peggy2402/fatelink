import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  IsBoolean,
  IsNotEmpty,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export class AiHistoryItemDto {
  @ApiProperty({ example: 'Hom nay minh met qua.' })
  @IsString()
  @IsNotEmpty()
  text!: string;

  @ApiProperty({ example: true })
  @IsBoolean()
  isSentByMe!: boolean;
}

export class SendAiMessageDto {
  @ApiProperty({ example: 'Hom nay minh hoi met moi chut...' })
  @IsString()
  @IsNotEmpty()
  message!: string;

  @ApiPropertyOptional({
    type: [AiHistoryItemDto],
    description: 'Lich su chat client gui kem',
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => AiHistoryItemDto)
  history?: AiHistoryItemDto[];
}

export class SuggestReplyDto {
  @ApiProperty({
    example: 'Ngọc Ánh',
    description: 'Tên đối phương (bạn chat)',
  })
  @IsString()
  @IsNotEmpty()
  partnerName!: string;

  @ApiPropertyOptional({
    example: 'Hôm nay đi làm về mệt quá cậu ơi...',
    description: 'Đoạn tin nhắn gần nhất của đối phương gửi',
  })
  @IsString()
  @IsOptional()
  lastPartnerMessage?: string;

  @ApiPropertyOptional({
    type: [String],
    description: 'Lịch sử vài tin nhắn ngữ cảnh trước đó',
  })
  @IsOptional()
  @IsArray()
  recentContext?: string[];
}

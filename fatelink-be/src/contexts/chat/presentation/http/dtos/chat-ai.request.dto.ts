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

import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  ArrayNotEmpty,
  IsBoolean,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';

export class AdminLoginDto {
  @ApiProperty({ example: 'admin' })
  @IsString()
  @IsNotEmpty({ message: 'Tài khoản không được để trống' })
  username!: string;

  @ApiProperty({ example: 'super-secret-password' })
  @IsString()
  @IsNotEmpty({ message: 'Mật khẩu không được để trống' })
  password!: string;
}

export class UpdateSystemConfigDto {
  @ApiPropertyOptional({
    example: 'Bạn là Faye, hãy trả lời ngắn gọn và đồng cảm.',
  })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  systemPrompt?: string;

  @ApiPropertyOptional({
    example: 'Một vài nguyên tắc tâm lý học hành vi cần ưu tiên.',
  })
  @IsOptional()
  @IsString()
  additionalKnowledge?: string;

  @ApiPropertyOptional({ example: 10 })
  @IsOptional()
  @IsInt()
  @Min(1)
  onboardingMessageLimit?: number;
}

export class BanUserDto {
  @ApiProperty({ example: true })
  @IsBoolean()
  isBanned!: boolean;
}

export class CreateAiModelDto {
  @ApiProperty({ example: 'gemini-2.0-flash' })
  @IsString()
  @IsNotEmpty()
  modelId!: string;

  @ApiProperty({ example: 'Gemini' })
  @IsString()
  @IsNotEmpty()
  providerName!: string;

  @ApiProperty({ example: 'Gemini 2.0 Flash' })
  @IsString()
  @IsNotEmpty()
  displayName!: string;

  @ApiProperty({ example: true })
  @IsBoolean()
  isEnabled!: boolean;

  @ApiProperty({ example: 0 })
  @IsInt()
  @Min(0)
  priority!: number;
}

export class UpdateAiModelDto {
  @ApiPropertyOptional({ example: 'gemini-2.0-flash' })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  modelId?: string;

  @ApiPropertyOptional({ example: 'Gemini' })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  providerName?: string;

  @ApiPropertyOptional({ example: 'Gemini 2.0 Flash' })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  displayName?: string;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  isEnabled?: boolean;

  @ApiPropertyOptional({ example: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  priority?: number;
}

export class ReorderAiModelsDto {
  @ApiProperty({
    example: ['6839f1d3a6cf02d1f5bf1111', '6839f1d3a6cf02d1f5bf2222'],
    type: [String],
  })
  @IsArray()
  @ArrayNotEmpty()
  @IsString({ each: true })
  modelIds!: string[];
}

export class TestAiChatDto {
  @ApiProperty({ example: 'Chao cau!' })
  @IsString()
  @IsNotEmpty()
  message!: string;

  @ApiPropertyOptional({ example: 'gemini-2.5-flash' })
  @IsOptional()
  @IsString()
  modelId?: string;

  @ApiPropertyOptional({ example: 'Gemini' })
  @IsOptional()
  @IsString()
  providerName?: string;

  @ApiPropertyOptional({ example: [{ role: 'user', text: 'hi' }, { role: 'assistant', text: 'Chao ban!' }] })
  @IsOptional()
  @IsArray()
  history?: { role: string; text: string }[];
}

export class SaveAdminLogDto {
  @ApiProperty({ example: 'Unhandled dashboard error' })
  @IsString()
  @IsNotEmpty()
  message!: string;

  @ApiProperty({ example: 'ERROR' })
  @IsString()
  @IsNotEmpty()
  type!: string;
}

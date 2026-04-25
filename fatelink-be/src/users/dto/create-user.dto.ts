import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateUserDto {
  @ApiProperty({ example: 'user@gmail.com', description: 'Email lấy từ Google' })
  readonly email: string;

  @ApiPropertyOptional({ example: 'Nguyễn Văn A', description: 'Tên hiển thị' })
  readonly name?: string;

  @ApiPropertyOptional({ example: 'https://lh3.googleusercontent.com/a/...', description: 'Avatar URL' })
  readonly avatar?: string;

  @ApiProperty({ example: '102938475630', description: 'ID định danh duy nhất của Google' })
  readonly googleId: string;
}
import { ApiProperty } from '@nestjs/swagger';

export class AuthUserDto {
  @ApiProperty({ example: '6836df5fbf1b9a2e38d31abc' })
  _id!: string;

  @ApiProperty({ example: 'user@example.com' })
  email!: string;

  @ApiProperty({ example: 'Nguyen Van A' })
  name!: string;

  @ApiProperty({
    example: 'https://lh3.googleusercontent.com/a/default-user=s96-c',
  })
  avatar!: string;

  @ApiProperty({ example: '116123456789012345678' })
  googleId!: string;

  @ApiProperty({ example: 'Bí ẩn' })
  latestEmotion!: string;

  @ApiProperty({ example: [5, 5, 5], type: [Number] })
  personality!: number[];

  @ApiProperty({ example: 'Đang tìm kiếm một kết nối định mệnh...' })
  bio!: string;

  @ApiProperty({ example: '' })
  fcmToken!: string;

  @ApiProperty({ example: 0 })
  tokenVersion!: number;

  @ApiProperty({ example: 1 })
  refreshTokenVersion!: number;

  @ApiProperty({ example: '3f7d0b44-b938-4f65-8d4d-4628d9b95c7e' })
  currentRefreshTokenId!: string;
}

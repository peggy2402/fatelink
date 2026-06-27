import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class AuthUserResponseDto {
  @ApiProperty({ example: '6a27fd10b87c32ba758a72ee' })
  id!: string;

  @ApiProperty({ example: '6a27fd10b87c32ba758a72ee' })
  _id!: string;

  @ApiPropertyOptional({ example: 'user@example.com' })
  email?: string;

  @ApiProperty({ example: 'Nguyen Van A' })
  name!: string;

  @ApiProperty({ example: '' })
  avatar!: string;

  @ApiProperty({ example: 'Bí ẩn' })
  latestEmotion!: string;

  @ApiProperty({
    example: {
      stress: 5,
      loneliness: 5,
      sadness: 5,
      calmness: 5,
      warmth: 5,
      happiness: 5,
    },
  })
  emotions!: {
    stress: number;
    loneliness: number;
    sadness: number;
    calmness: number;
    warmth: number;
    happiness: number;
  };

  @ApiProperty({ example: [5, 5, 5], type: [Number] })
  personality!: number[];

  @ApiProperty({ example: 'Đang tìm kiếm một kết nối định mệnh...' })
  bio!: string;

  @ApiProperty({ example: '' })
  fcmToken!: string;
}

export class AuthTokensResponseDto {
  @ApiProperty({ example: true })
  success!: true;

  @ApiProperty({ example: 'Đăng nhập email thành công!' })
  message!: string;

  @ApiProperty({ type: AuthUserResponseDto })
  data!: AuthUserResponseDto;

  @ApiProperty({ example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.access' })
  accessToken!: string;

  @ApiProperty({ example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.refresh' })
  refreshToken!: string;
}

export class RequestPhoneOtpDataDto {
  @ApiProperty({ example: '2026-06-10T12:00:00.000Z' })
  expiresAt!: Date;

  @ApiPropertyOptional({ example: '123456' })
  otpCode?: string;
}

export class RequestPhoneOtpResponseDto {
  @ApiProperty({ example: true })
  success!: true;

  @ApiProperty({ example: 'Yêu cầu OTP thành công.' })
  message!: string;

  @ApiProperty({ type: RequestPhoneOtpDataDto })
  data!: RequestPhoneOtpDataDto;
}

export class RequestMagicLinkDataDto {
  @ApiProperty({ example: '2026-06-10T12:00:00.000Z' })
  expiresAt!: Date;

  @ApiPropertyOptional({
    example: 'http://localhost:3000/magic-link?token=user%40example.com.abcd',
  })
  magicLink?: string;
}

export class RequestMagicLinkResponseDto {
  @ApiProperty({ example: true })
  success!: true;

  @ApiProperty({ example: 'Yêu cầu magic link thành công.' })
  message!: string;

  @ApiProperty({ type: RequestMagicLinkDataDto })
  data!: RequestMagicLinkDataDto;
}

export class AuthSessionItemDto {
  @ApiProperty({ example: '817d7c9e-f294-407b-8989-40cd66c3bc62' })
  sessionId!: string;

  @ApiProperty({ example: '6a27fd10b87c32ba758a72ee' })
  userId!: string;

  @ApiProperty({ example: 'mobile' })
  deviceType!: string;

  @ApiProperty({ example: 'postman-device-1' })
  deviceId!: string;

  @ApiProperty({ example: 'active' })
  status!: string;

  @ApiPropertyOptional({ example: '127.0.0.1' })
  ipAddress?: string;

  @ApiPropertyOptional({ example: 'PostmanRuntime/7.44.1' })
  userAgent?: string;

  @ApiProperty({ example: '2026-06-10T10:00:00.000Z' })
  createdAt!: Date;

  @ApiProperty({ example: '2026-06-10T10:05:00.000Z' })
  lastRefreshedAt!: Date;

  @ApiProperty({ example: '2026-06-10T10:05:00.000Z' })
  lastSeenAt!: Date;

  @ApiPropertyOptional({ example: '2026-06-10T10:06:00.000Z' })
  revokedAt?: Date;

  @ApiPropertyOptional({ example: 'device_relogin' })
  revokedReason?: string;

  @ApiPropertyOptional({ example: 'another-session-id' })
  replacedBySessionId?: string;

  @ApiProperty({ example: true })
  current!: boolean;
}

export class ListAuthSessionsResponseDto {
  @ApiProperty({ example: true })
  success!: true;

  @ApiProperty({ example: 'Lấy danh sách session thành công.' })
  message!: string;

  @ApiProperty({ type: [AuthSessionItemDto] })
  data!: AuthSessionItemDto[];
}

export class SimpleMessageResponseDto {
  @ApiProperty({ example: true })
  success!: true;

  @ApiProperty({ example: 'Đăng xuất thành công, token đã bị thu hồi.' })
  message!: string;
}

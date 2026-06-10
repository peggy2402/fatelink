import { ApiProperty } from '@nestjs/swagger';
import { DeviceType } from '@contexts/auth/application/contracts/device-type';
import {
  IsEmail,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';

export class LoginWithGoogleDto {
  @ApiProperty({
    example: 'eyJhbGciOiJSUzI1...',
    description: 'ID token tu Google OAuth',
  })
  @IsString()
  @IsNotEmpty()
  token!: string;

  @ApiProperty({
    enum: DeviceType,
    example: DeviceType.MOBILE,
    description: 'Loại thiết bị đang đăng nhập.',
    required: false,
    default: DeviceType.MOBILE,
  })
  @IsEnum(DeviceType)
  deviceType: DeviceType = DeviceType.MOBILE;

  @ApiProperty({ example: 'iphone-15-pro-max-user-123' })
  @IsString()
  @IsNotEmpty()
  deviceId!: string;
}

export class RefreshTokenDto {
  @ApiProperty({
    example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.refresh-token',
    description: 'Refresh token được cấp từ lần đăng nhập trước.',
  })
  @IsString()
  @IsNotEmpty()
  refreshToken!: string;

  @ApiProperty({
    example: 'iphone-15-pro-max-user-123',
    description: 'Định danh thiết bị đã nhận refresh token.',
  })
  @IsString()
  @IsNotEmpty()
  deviceId!: string;
}

export class RegisterWithEmailDto {
  @ApiProperty({ example: 'user@example.com' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'super-secret-password' })
  @IsString()
  @MinLength(6)
  password!: string;

  @ApiProperty({ example: 'Nguyen Van A', required: false })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiProperty({
    enum: DeviceType,
    example: DeviceType.MOBILE,
    default: DeviceType.MOBILE,
  })
  @IsEnum(DeviceType)
  deviceType: DeviceType = DeviceType.MOBILE;

  @ApiProperty({ example: 'iphone-15-pro-max-user-123' })
  @IsString()
  @IsNotEmpty()
  deviceId!: string;
}

export class LoginWithEmailDto {
  @ApiProperty({ example: 'user@example.com' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'super-secret-password' })
  @IsString()
  @MinLength(6)
  password!: string;

  @ApiProperty({
    enum: DeviceType,
    example: DeviceType.MOBILE,
    default: DeviceType.MOBILE,
  })
  @IsEnum(DeviceType)
  deviceType: DeviceType = DeviceType.MOBILE;

  @ApiProperty({ example: 'iphone-15-pro-max-user-123' })
  @IsString()
  @IsNotEmpty()
  deviceId!: string;
}

export class RequestPhoneOtpDto {
  @ApiProperty({ example: '+84901234567' })
  @IsString()
  @IsNotEmpty()
  phoneNumber!: string;

  @ApiProperty({ example: 'Nguyen Van A', required: false })
  @IsOptional()
  @IsString()
  name?: string;
}

export class LoginWithPhoneOtpDto {
  @ApiProperty({ example: '+84901234567' })
  @IsString()
  @IsNotEmpty()
  phoneNumber!: string;

  @ApiProperty({ example: '123456' })
  @IsString()
  @IsNotEmpty()
  otpCode!: string;

  @ApiProperty({
    enum: DeviceType,
    example: DeviceType.MOBILE,
    default: DeviceType.MOBILE,
  })
  @IsEnum(DeviceType)
  deviceType: DeviceType = DeviceType.MOBILE;

  @ApiProperty({ example: 'iphone-15-pro-max-user-123' })
  @IsString()
  @IsNotEmpty()
  deviceId!: string;
}

export class RequestMagicLinkDto {
  @ApiProperty({ example: 'user@example.com' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'Nguyen Van A', required: false })
  @IsOptional()
  @IsString()
  name?: string;
}

export class LoginWithMagicLinkDto {
  @ApiProperty({ example: 'user%40example.com.abcd1234' })
  @IsString()
  @IsNotEmpty()
  token!: string;

  @ApiProperty({
    enum: DeviceType,
    example: DeviceType.WEB,
    default: DeviceType.WEB,
  })
  @IsEnum(DeviceType)
  deviceType: DeviceType = DeviceType.WEB;

  @ApiProperty({ example: 'chrome-macbook-user-123' })
  @IsString()
  @IsNotEmpty()
  deviceId!: string;
}

export class LoginWithFacebookDto {
  @ApiProperty({
    example: 'EAABsbCS1iHgBA...',
    description: 'Facebook access token',
  })
  @IsString()
  @IsNotEmpty()
  accessToken!: string;

  @ApiProperty({
    enum: DeviceType,
    example: DeviceType.MOBILE,
    default: DeviceType.MOBILE,
  })
  @IsEnum(DeviceType)
  deviceType: DeviceType = DeviceType.MOBILE;

  @ApiProperty({ example: 'iphone-15-pro-max-user-123' })
  @IsString()
  @IsNotEmpty()
  deviceId!: string;
}

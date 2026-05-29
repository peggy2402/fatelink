import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsString, MinLength } from 'class-validator';
import { DeviceType } from './device-type.enum';

export class GoogleAuthTokenDto {
  @ApiProperty({
    example: 'eyJhbGciOiJSUzI1NiIsImtpZCI6Ij...',
    description: 'Google ID token lấy từ client.',
  })
  @IsString()
  @MinLength(1)
  readonly token!: string;

  @ApiProperty({
    enum: DeviceType,
    example: DeviceType.MOBILE,
    description:
      'Loại thiết bị đang đăng nhập. Mỗi user chỉ có tối đa 1 session hoạt động cho mỗi loại thiết bị.',
  })
  @IsEnum(DeviceType)
  readonly deviceType!: DeviceType;
}

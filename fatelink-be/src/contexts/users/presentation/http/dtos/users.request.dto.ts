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

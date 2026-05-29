import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

export class GoogleAuthTokenDto {
  @ApiProperty({
    example: 'eyJhbGciOiJSUzI1NiIsImtpZCI6Ij...',
    description: 'Google ID token lấy từ client.',
  })
  @IsString()
  @MinLength(1)
  readonly token!: string;
}

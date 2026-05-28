import { ApiProperty } from '@nestjs/swagger';

export class GoogleAuthTokenDto {
  @ApiProperty({
    example: 'eyJhbGciOiJSUzI1NiIsImtpZCI6Ij...',
    description: 'Google ID token lấy từ client.',
  })
  readonly token!: string;
}

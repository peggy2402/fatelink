import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class GoogleLoginDto {
  @ApiProperty({
    example: 'eyJhbGciOiJSUzI1...',
    description: 'ID token tu Google OAuth',
  })
  @IsString()
  @IsNotEmpty()
  token!: string;
}

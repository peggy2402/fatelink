import { ApiProperty } from '@nestjs/swagger';
import { AuthUserDto } from './auth-user.dto';

export class AuthTokenPairResponseDto {
  @ApiProperty({ type: AuthUserDto })
  user!: AuthUserDto;

  @ApiProperty({
    example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.access-token',
  })
  accessToken!: string;

  @ApiProperty({
    example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.refresh-token',
  })
  refreshToken!: string;
}

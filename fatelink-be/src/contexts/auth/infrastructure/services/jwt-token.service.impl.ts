import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import type {
  AccessTokenPayload,
  TokenService,
} from '@shared/contracts/token.service';

@Injectable()
export class JwtTokenServiceImpl implements TokenService {
  private readonly jwtSecret = process.env.JWT_SECRET || 'fallback_secret';

  constructor(private readonly jwtService: JwtService) {}

  signAccessToken(payload: AccessTokenPayload): string {
    return this.jwtService.sign(payload, {
      secret: this.jwtSecret,
      expiresIn: '7d',
    });
  }

  async verifyAccessToken(token: string): Promise<AccessTokenPayload> {
    return this.jwtService.verifyAsync<AccessTokenPayload>(token, {
      secret: this.jwtSecret,
    });
  }
}

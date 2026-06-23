import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import type { StringValue } from 'ms';
import type {
  AccessTokenPayload,
  TokenService,
} from '@shared/contracts/token.service';
import { AUTH_ENV } from '@contexts/auth/infrastructure/config/auth-env';

@Injectable()
export class JwtTokenServiceImpl implements TokenService {
  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  signAccessToken(payload: AccessTokenPayload): string {
    return this.jwtService.sign(payload, {
      secret: this.configService.getOrThrow<string>(AUTH_ENV.jwtSecret),
      expiresIn: this.getAccessTokenExpiresIn(),
    });
  }

  async verifyAccessToken(token: string): Promise<AccessTokenPayload> {
    return this.jwtService.verifyAsync<AccessTokenPayload>(token, {
      secret: this.configService.getOrThrow<string>(AUTH_ENV.jwtSecret),
    });
  }

  private getAccessTokenExpiresIn(): StringValue {
    return (this.configService.get<string>(AUTH_ENV.jwtAccessExpiresIn) ||
      '5m') as StringValue;
  }
}

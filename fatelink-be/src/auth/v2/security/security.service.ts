import { Injectable } from '@nestjs/common';
import { AuthTokenService } from '../services/auth-token.service';

@Injectable()
export class SecurityService {
  constructor(private readonly authTokenService: AuthTokenService) {}

  async logout(userId: string) {
    return this.authTokenService.revokeAllTokens(userId);
  }

  async refresh(refreshToken: string) {
    return this.authTokenService.refreshTokenPair(refreshToken);
  }
}

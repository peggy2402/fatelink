import { Injectable } from '@nestjs/common';
import { AuthTokenService } from '../services/auth-token.service';
import { DeviceType } from '../dto/device-type.enum';

@Injectable()
export class SecurityService {
  constructor(private readonly authTokenService: AuthTokenService) {}

  async logout(userId: string, deviceType?: DeviceType) {
    return this.authTokenService.revokeAllTokens(userId, deviceType);
  }

  async refresh(refreshToken: string) {
    return this.authTokenService.refreshTokenPair(refreshToken);
  }
}

import { Injectable } from '@nestjs/common';
import { AppLoggerService } from '../../../common/logger/logger.service';
import { DeviceType } from '../dto/device-type.enum';
import { AuthTokenService } from '../services/auth-token.service';
import { AuthUserService } from '../services/auth-user.service';
import { GoogleTokenService } from '../services/google-token.service';

@Injectable()
export class GoogleService {
  constructor(
    private readonly googleTokenService: GoogleTokenService,
    private readonly authUserService: AuthUserService,
    private readonly authTokenService: AuthTokenService,
    private readonly logger: AppLoggerService,
  ) {}

  async authenticate(token: string, deviceType: DeviceType) {
    const profile = await this.googleTokenService.verifyIdToken(token);
    const user = await this.authUserService.authenticateWithGoogle(profile);
    const tokenPair = await this.authTokenService.issueTokenPair(
      user,
      deviceType,
    );

    this.logger.infoEvent('user_login_succeeded', {
      message: 'User login succeeded',
      user_id: user.id,
      actor_id: user.id,
      entity_type: 'user',
      entity_id: user.id,
      metadata: {
        provider: 'google',
        email: profile.email,
        device_type: deviceType,
      },
    });

    return tokenPair;
  }
}

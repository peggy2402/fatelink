import { Injectable } from '@nestjs/common';
import { AuthTokenService } from '../services/auth-token.service';
import { AuthUserService } from '../services/auth-user.service';
import { GoogleTokenService } from '../services/google-token.service';

@Injectable()
export class GoogleService {
  constructor(
    private readonly googleTokenService: GoogleTokenService,
    private readonly authUserService: AuthUserService,
    private readonly authTokenService: AuthTokenService,
  ) {}

  async authenticate(token: string) {
    const profile = await this.googleTokenService.verifyIdToken(token);
    const user = await this.authUserService.authenticateWithGoogle(profile);
    return this.authTokenService.issueTokenPair(user);
  }
}

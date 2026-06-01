import {
  OAuth2Client,
  type LoginTicket,
  type TokenPayload,
} from 'google-auth-library';
import type {
  GoogleAuthService,
  GoogleUserProfile,
} from '@shared/contracts/google-auth.service';
import {
  BadRequestApplicationError,
  UnauthorizedApplicationError,
} from '@shared/errors/application-error';

export class GoogleAuthServiceImpl implements GoogleAuthService {
  private readonly client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

  async verifyIdToken(token: string): Promise<GoogleUserProfile> {
    if (!token || token.split('.').length !== 3) {
      throw new BadRequestApplicationError(
        'Google ID token khong dung dinh dang.',
      );
    }

    let ticket: LoginTicket;
    try {
      ticket = await this.client.verifyIdToken({
        idToken: token,
        audience: process.env.GOOGLE_CLIENT_ID,
      });
    } catch {
      throw new UnauthorizedApplicationError(
        'Google ID token khong hop le hoac da het han.',
      );
    }

    const payload: TokenPayload | undefined = ticket.getPayload();

    if (!payload?.email || !payload.sub) {
      throw new UnauthorizedApplicationError(
        'Không thể xác thực tài khoản Google.',
      );
    }

    return {
      email: payload.email,
      name: payload.name,
      avatar: payload.picture,
      googleId: payload.sub,
    };
  }
}

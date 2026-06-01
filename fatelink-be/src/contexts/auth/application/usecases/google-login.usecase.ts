import type { GoogleAuthService } from '@shared/contracts/google-auth.service';
import type { TokenService } from '@shared/contracts/token.service';
import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';

export class GoogleLoginUseCase {
  constructor(
    private readonly googleAuthService: GoogleAuthService,
    private readonly userRepository: UserRepository,
    private readonly tokenService: TokenService,
  ) {}

  async execute(input: { token: string }) {
    const profile = await this.googleAuthService.verifyIdToken(input.token);
    const user = await this.userRepository.findOrCreate(profile);
    const userId = user.id || '';

    const accessToken = this.tokenService.signAccessToken({
      sub: userId,
      email: user.email,
      tokenVersion: user.tokenVersion || 0,
    });

    return { user, accessToken };
  }
}

import { UnauthorizedApplicationError } from '@shared/errors/application-error';
import type { TokenService } from '@shared/contracts/token.service';
import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';

export class ValidateUserTokenUseCase {
  constructor(
    private readonly tokenService: TokenService,
    private readonly userRepository: UserRepository,
  ) {}

  async execute(input: { token: string }) {
    const payload = await this.tokenService.verifyAccessToken(input.token);
    const user = await this.userRepository.findById(payload.sub);

    if (!user || user.tokenVersion !== payload.tokenVersion) {
      throw new UnauthorizedApplicationError(
        'Token đã bị thu hồi do đăng xuất ở thiết bị khác.',
      );
    }

    return payload;
  }
}

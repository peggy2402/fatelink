import type { MagicLinkAuthService } from '@shared/contracts/magic-link-auth.service';

export class RequestMagicLinkUseCase {
  constructor(private readonly magicLinkAuthService: MagicLinkAuthService) {}

  execute(input: { email: string; name?: string }) {
    return this.magicLinkAuthService.requestLink(input);
  }
}

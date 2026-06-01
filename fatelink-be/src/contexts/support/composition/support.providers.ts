import type { SupportNotifierService } from '@shared/contracts/support-notifier.service';
import { SubmitSupportUseCase } from '@contexts/support/application/usecases/submit-support.usecase';
import { SUPPORT_APPLICATION_TOKENS } from './support.tokens';
import { SUPPORT_NOTIFIER_SERVICE } from '@shared/kernel/injection-tokens';
import type { Provider } from '@nestjs/common';

export const supportUseCaseProviders: Provider[] = [
  {
    provide: SUPPORT_APPLICATION_TOKENS.submitSupport,
    useFactory: (supportNotifier: SupportNotifierService) =>
      new SubmitSupportUseCase(supportNotifier),
    inject: [SUPPORT_NOTIFIER_SERVICE],
  },
];

export const supportUseCases = [SUPPORT_APPLICATION_TOKENS.submitSupport];

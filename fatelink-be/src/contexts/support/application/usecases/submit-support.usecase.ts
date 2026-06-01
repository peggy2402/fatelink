import type { SupportNotifierService } from '@shared/contracts/support-notifier.service';
import { type SupportRequest } from '@contexts/support/application/contracts/support.request';

export class SubmitSupportUseCase {
  constructor(private readonly supportNotifier: SupportNotifierService) {}

  async execute(input: SupportRequest) {
    await this.supportNotifier.submit(input);
    return { message: 'Đã gửi yêu cầu hỗ trợ thành công' };
  }
}

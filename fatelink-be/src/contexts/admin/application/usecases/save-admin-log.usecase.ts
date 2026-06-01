import type { AdminLogService } from '@shared/contracts/admin-log.service';

export class SaveAdminLogUseCase {
  constructor(private readonly adminLogService: AdminLogService) {}

  execute(input: { message: string; type: string }) {
    this.adminLogService.append(input.message, input.type);
    return { success: true };
  }
}

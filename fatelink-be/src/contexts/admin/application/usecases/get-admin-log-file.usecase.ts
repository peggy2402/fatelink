import type { AdminLogService } from '@shared/contracts/admin-log.service';

export class GetAdminLogFileUseCase {
  constructor(private readonly adminLogService: AdminLogService) {}

  execute() {
    return this.adminLogService.getLogFile();
  }
}

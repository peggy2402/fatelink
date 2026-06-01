import type { UpdateSystemConfigCommand } from '@contexts/admin/application/contracts/admin.commands';
import type { SystemConfigRepository } from '@contexts/admin/domain/repositories/system-config.repository';

export class UpdateSystemConfigUseCase {
  constructor(
    private readonly systemConfigRepository: SystemConfigRepository,
  ) {}

  execute(input: UpdateSystemConfigCommand) {
    return this.systemConfigRepository.updateConfig(input);
  }
}

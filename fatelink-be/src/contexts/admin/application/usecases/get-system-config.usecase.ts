import type { SystemConfigRepository } from '@contexts/admin/domain/repositories/system-config.repository';

export class GetSystemConfigUseCase {
  constructor(
    private readonly systemConfigRepository: SystemConfigRepository,
  ) {}

  execute() {
    return this.systemConfigRepository.getConfig();
  }
}

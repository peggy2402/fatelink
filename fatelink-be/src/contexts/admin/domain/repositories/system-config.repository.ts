import type { UpdateSystemConfigCommand } from '@contexts/admin/application/contracts/admin.commands';
import { type SystemConfig } from '@contexts/admin/domain/entities/system-config';

export interface SystemConfigRepository {
  getConfig(): Promise<SystemConfig>;
  updateConfig(
    updateData: UpdateSystemConfigCommand,
  ): Promise<SystemConfig | null>;
}

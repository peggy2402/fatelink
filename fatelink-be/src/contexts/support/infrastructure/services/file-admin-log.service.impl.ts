import * as fs from 'node:fs';
import * as path from 'node:path';
import type {
  AdminLogFile,
  AdminLogService,
} from '@shared/contracts/admin-log.service';

export class FileAdminLogServiceImpl implements AdminLogService {
  private readonly logDir = path.join(process.cwd(), 'logs');
  private readonly logFile = path.join(this.logDir, 'admin.log');

  append(message: string, type: string): void {
    fs.mkdirSync(this.logDir, { recursive: true });
    const timestamp = new Date().toISOString();
    fs.appendFileSync(this.logFile, `[${timestamp}] [${type}] ${message}\n`);
  }

  getLogFile(): AdminLogFile | null {
    if (!fs.existsSync(this.logFile)) {
      return null;
    }

    return {
      path: this.logFile,
      filename: 'admin.log',
    };
  }
}

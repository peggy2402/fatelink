export interface AdminLogFile {
  path: string;
  filename: string;
}

export interface AdminLogService {
  append(message: string, type: string): void;
  getLogFile(): AdminLogFile | null;
}

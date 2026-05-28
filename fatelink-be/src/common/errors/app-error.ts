import { AppErrorCode } from './app-error-codes';

export class AppError extends Error {
  constructor(
    public readonly code: AppErrorCode,
    message?: string,
    public readonly details?: unknown,
  ) {
    super(message ?? code);
    this.name = 'AppError';
  }
}

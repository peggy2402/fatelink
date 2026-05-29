import { AppErrorCode } from './app-error-codes';

export type AppErrorKind =
  | 'validation'
  | 'business'
  | 'integration'
  | 'infrastructure'
  | 'unexpected';

export type AppErrorLayer =
  | 'controller'
  | 'guard'
  | 'service'
  | 'repository'
  | 'external_api'
  | 'unknown';

export type AppErrorDomain = 'auth' | 'user' | 'system' | 'unknown';

export type AppErrorMetadata = {
  domain?: AppErrorDomain;
  layer?: AppErrorLayer;
  kind?: AppErrorKind;
  source?: string;
  provider?: string;
  retryable?: boolean;
  entityType?: string;
  entityId?: string;
  userId?: string;
  actorId?: string;
};

export class AppError extends Error {
  constructor(
    public readonly code: AppErrorCode,
    message?: string,
    public readonly details?: unknown,
    public readonly metadata?: AppErrorMetadata,
    public readonly cause?: unknown,
  ) {
    super(message ?? code);
    this.name = 'AppError';
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

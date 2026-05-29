import { Request } from 'express';

export type LogLevel = 'debug' | 'info' | 'warn' | 'error' | 'fatal';

export type LogMetadata = Record<string, unknown>;

export type AuthenticatedRequestUser = {
  sub?: string;
  id?: string;
  userId?: string;
  actorId?: string;
  role?: string;
};

export type RequestContextStore = {
  request_id: string;
  trace_id: string;
  span_id?: string;
  user_id?: string;
  actor_id?: string;
};

export type RequestWithContext = Request & {
  requestId?: string;
  traceId?: string;
  spanId?: string;
  user?: AuthenticatedRequestUser;
};

export type LogContext = {
  message?: string;
  request_id?: string;
  trace_id?: string;
  span_id?: string;
  user_id?: string;
  actor_id?: string;
  entity_type?: string;
  entity_id?: string;
  duration_ms?: number;
  error_code?: string;
  error_message?: string;
  retryable?: boolean;
  metadata?: LogMetadata;
};

export type ExternalApiLogContext = {
  provider: string;
  operation: string;
  status_code?: number;
  duration_ms: number;
  retryable?: boolean;
  error_code?: string;
  entity_type?: string;
  entity_id?: string;
  metadata?: LogMetadata;
};

export type SerializedError = {
  name: string;
  message: string;
  stack?: string;
  cause?: SerializedError | string;
  details?: unknown;
};

export type LogRecord = {
  timestamp?: string;
  level: LogLevel;
  service: string;
  env: string;
  version: string;
  event: string;
  message: string;
  request_id?: string;
  trace_id?: string;
  span_id?: string;
  user_id?: string;
  actor_id?: string;
  entity_type?: string;
  entity_id?: string;
  duration_ms?: number;
  error_code?: string;
  error_message?: string;
  retryable?: boolean;
  metadata?: LogMetadata;
  error?: SerializedError;
};

export type LoggerRuntimeConfig = {
  service: string;
  env: string;
  version: string;
  level: LogLevel;
  include_stack: boolean;
  pretty_print: boolean;
  pretty_format: 'human' | 'json' | 'text';
};

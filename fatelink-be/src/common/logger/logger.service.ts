import { Injectable, LoggerService as NestLoggerService } from '@nestjs/common';
import { Writable } from 'stream';
import pino, {
  DestinationStream,
  Logger as PinoLogger,
  LoggerOptions,
  TransportTargetOptions,
} from 'pino';
import { AppError } from '../errors/app-error';
import { resolveLoggerRuntimeConfig } from './logger.config';
import {
  ExternalApiLogContext,
  LogContext,
  LogLevel,
  LogMetadata,
  LogRecord,
  LoggerRuntimeConfig,
  RequestWithContext,
  SerializedError,
} from './log.types';
import { RequestContextService } from './request-context.service';
import { SensitiveDataRedactor } from './sensitive-data-redactor';

@Injectable()
export class AppLoggerService implements NestLoggerService {
  private readonly config: LoggerRuntimeConfig;
  private readonly logger: PinoLogger;

  constructor(
    private readonly requestContext: RequestContextService,
    private readonly redactor: SensitiveDataRedactor,
  ) {
    this.config = resolveLoggerRuntimeConfig();
    this.logger = pino(this.buildLoggerOptions(), this.buildDestination());
  }

  log(message: unknown, context?: string): void {
    if (this.shouldSkipNestInfoLog(context, message)) {
      return;
    }

    this.infoEvent('nest_log', {
      message: this.stringifyMessage(message),
      metadata: context ? { context } : undefined,
    });
  }

  error(message: unknown, trace?: string, context?: string): void {
    this.write('error', 'nest_error', {
      message: this.stringifyMessage(message),
      metadata: this.compactMetadata({
        context,
        trace,
      }),
    });
  }

  warn(message: unknown, context?: string): void {
    this.warnEvent('nest_warn', {
      message: this.stringifyMessage(message),
      metadata: context ? { context } : undefined,
    });
  }

  debug(message: unknown, context?: string): void {
    this.debugEvent('nest_debug', {
      message: this.stringifyMessage(message),
      metadata: context ? { context } : undefined,
    });
  }

  verbose(message: unknown, context?: string): void {
    this.debugEvent('nest_verbose', {
      message: this.stringifyMessage(message),
      metadata: context ? { context } : undefined,
    });
  }

  fatal(message: unknown, trace?: string, context?: string): void {
    this.fatalEvent('nest_fatal', {
      message: this.stringifyMessage(message),
      metadata: this.compactMetadata({
        context,
        trace,
      }),
    });
  }

  infoEvent(event: string, context: LogContext = {}): void {
    this.write('info', event, context);
  }

  logEvent(level: LogLevel, event: string, context: LogContext = {}): void {
    this.write(level, event, context);
  }

  warnEvent(event: string, context: LogContext = {}): void {
    this.write('warn', event, context);
  }

  debugEvent(event: string, context: LogContext = {}): void {
    this.write('debug', event, context);
  }

  fatalEvent(event: string, context: LogContext = {}): void {
    this.write('fatal', event, context);
  }

  errorEvent(event: string, error: unknown, context: LogContext = {}): void {
    this.write('error', event, context, error);
  }

  logExternalApi(event: string, context: ExternalApiLogContext): void {
    this.infoEvent(event, {
      message: `${context.provider}.${context.operation}`,
      entity_type: context.entity_type,
      entity_id: context.entity_id,
      duration_ms: context.duration_ms,
      retryable: context.retryable,
      error_code: context.error_code,
      metadata: this.compactMetadata({
        provider: context.provider,
        operation: context.operation,
        status_code: context.status_code,
        ...context.metadata,
      }),
    });
  }

  errorExternalApi(
    event: string,
    error: unknown,
    context: ExternalApiLogContext,
  ): void {
    this.errorEvent(event, error, {
      message: `${context.provider}.${context.operation}`,
      entity_type: context.entity_type,
      entity_id: context.entity_id,
      duration_ms: context.duration_ms,
      retryable: context.retryable,
      error_code: context.error_code,
      metadata: this.compactMetadata({
        provider: context.provider,
        operation: context.operation,
        status_code: context.status_code,
        ...context.metadata,
      }),
    });
  }

  assignRequestUser(request: RequestWithContext): void {
    this.requestContext.assignUser(request.user);
  }

  private write(
    level: LogLevel,
    event: string,
    context: LogContext,
    error?: unknown,
  ): void {
    const store = this.requestContext.get();
    const serializedError = error
      ? this.serializeError(error, this.config.include_stack)
      : undefined;

    const record: LogRecord = {
      level,
      service: this.config.service,
      env: this.config.env,
      version: this.config.version,
      event,
      message: context.message ?? event,
      request_id: context.request_id ?? store?.request_id,
      trace_id: context.trace_id ?? store?.trace_id,
      span_id: context.span_id ?? store?.span_id,
      user_id: context.user_id ?? store?.user_id,
      actor_id: context.actor_id ?? store?.actor_id,
      entity_type: context.entity_type,
      entity_id: context.entity_id,
      duration_ms: context.duration_ms,
      error_code:
        context.error_code ?? this.resolveErrorCode(error ?? serializedError),
      error_message:
        context.error_message ??
        (serializedError ? serializedError.message : undefined),
      retryable: context.retryable ?? this.resolveRetryable(error),
      metadata: this.redactMetadata(context.metadata),
      error: serializedError,
    };

    this.logger[level](record);
  }

  private redactMetadata(metadata?: LogMetadata): LogMetadata | undefined {
    if (!metadata) {
      return undefined;
    }

    return this.redactor.redact(metadata);
  }

  private serializeError(
    error: unknown,
    includeStack: boolean,
    depth = 0,
  ): SerializedError {
    if (depth > 3) {
      return { name: 'Error', message: '[MaxErrorDepthExceeded]' };
    }

    if (error instanceof AppError) {
      return {
        name: error.name,
        message: error.message,
        stack: includeStack ? error.stack : undefined,
        cause: error.cause
          ? this.serializeUnknownCause(error.cause, includeStack, depth + 1)
          : undefined,
        details: this.redactor.redact(error.details),
      };
    }

    if (error instanceof Error) {
      const nestedCause =
        'cause' in error
          ? this.serializeUnknownCause(
              (error as Error & { cause?: unknown }).cause,
              includeStack,
              depth + 1,
            )
          : undefined;

      return {
        name: error.name,
        message: error.message,
        stack: includeStack ? error.stack : undefined,
        cause: nestedCause,
      };
    }

    return {
      name: 'Error',
      message: this.stringifyMessage(error),
    };
  }

  private serializeUnknownCause(
    cause: unknown,
    includeStack: boolean,
    depth: number,
  ): SerializedError | string | undefined {
    if (!cause) {
      return undefined;
    }

    if (cause instanceof Error || cause instanceof AppError) {
      return this.serializeError(cause, includeStack, depth);
    }

    if (typeof cause === 'string') {
      return cause;
    }

    return this.stringifyMessage(this.redactor.redact(cause));
  }

  private resolveErrorCode(error: unknown): string | undefined {
    if (error instanceof AppError) {
      return error.code;
    }

    return undefined;
  }

  private resolveRetryable(error: unknown): boolean | undefined {
    if (error instanceof AppError) {
      return error.metadata?.retryable;
    }

    return undefined;
  }

  private stringifyMessage(value: unknown): string {
    if (typeof value === 'string') {
      return value;
    }

    if (value instanceof Error) {
      return value.message;
    }

    return JSON.stringify(this.redactor.redact(value));
  }

  private compactMetadata(
    metadata: LogMetadata | undefined,
  ): LogMetadata | undefined {
    if (!metadata) {
      return undefined;
    }

    const entries = Object.entries(metadata).filter(
      ([, value]) => value !== undefined,
    );
    return entries.length > 0 ? Object.fromEntries(entries) : undefined;
  }

  private buildLoggerOptions(): LoggerOptions {
    const options: LoggerOptions = {
      level: this.config.level,
      base: undefined,
      messageKey: 'message',
      formatters: {
        level: (label: string) => ({ level: label }),
      },
      timestamp: () => `,"timestamp":"${new Date().toISOString()}"`,
    };

    return options;
  }

  private buildDestination(): DestinationStream | undefined {
    if (!this.config.pretty_print) {
      return undefined;
    }

    if (this.config.pretty_format === 'human') {
      return new HumanReadableDestination();
    }

    if (this.config.pretty_format === 'json') {
      return new PrettyJsonDestination();
    }

    const targets: TransportTargetOptions[] = [
      {
        target: 'pino-pretty',
        options: {
          colorize: true,
          ignore: 'pid,hostname',
          messageFormat:
            '{event} | {message} | req={request_id} trace={trace_id}',
          translateTime: 'SYS:standard',
          singleLine: false,
        },
      },
    ];

    const transport = pino.transport({ targets });
    return transport as DestinationStream;
  }

  private shouldSkipNestInfoLog(
    context: string | undefined,
    message: unknown,
  ): boolean {
    if (typeof message !== 'string') {
      return false;
    }

    return (
      context === 'InstanceLoader' ||
      context === 'RoutesResolver' ||
      context === 'RouterExplorer' ||
      context === 'WebSocketsController' ||
      context === 'NestApplication'
    );
  }
}

class PrettyJsonDestination extends Writable {
  _write(
    chunk: Buffer | string,
    _encoding: BufferEncoding,
    callback: (error?: Error | null) => void,
  ): void {
    try {
      const raw = chunk.toString().trim();

      if (!raw) {
        callback();
        return;
      }

      const parsed = JSON.parse(raw) as Record<string, unknown>;
      process.stdout.write(`${JSON.stringify(parsed, null, 2)}\n`);
      callback();
    } catch (error) {
      callback(error instanceof Error ? error : new Error(String(error)));
    }
  }
}

class HumanReadableDestination extends Writable {
  _write(
    chunk: Buffer | string,
    _encoding: BufferEncoding,
    callback: (error?: Error | null) => void,
  ): void {
    try {
      const raw = chunk.toString().trim();

      if (!raw) {
        callback();
        return;
      }

      const record = JSON.parse(raw) as LogRecord;
      process.stdout.write(`${this.formatRecord(record)}\n`);
      callback();
    } catch (error) {
      callback(error instanceof Error ? error : new Error(String(error)));
    }
  }

  private formatRecord(record: LogRecord): string {
    const lines: string[] = [];
    const time = record.timestamp ?? new Date().toISOString();
    const level = record.level.toUpperCase().padEnd(5, ' ');
    const event = record.event;
    const message = record.message;

    lines.push(`${time} ${level} ${event}  ${message}`);

    const summaryParts = [
      this.asPair('req', record.request_id),
      this.asPair('trace', record.trace_id),
      this.asPair('span', record.span_id),
      this.asPair('user', record.user_id),
      this.asPair('actor', record.actor_id),
      this.asPair(
        'entity',
        this.joinEntity(record.entity_type, record.entity_id),
      ),
      this.asPair('duration_ms', this.asValue(record.duration_ms)),
      this.asPair('error_code', record.error_code),
      this.asPair('retryable', this.asValue(record.retryable)),
    ].filter(Boolean);

    if (summaryParts.length > 0) {
      lines.push(`  ${summaryParts.join('  ')}`);
    }

    if (record.error_message) {
      lines.push(`  error_message: ${record.error_message}`);
    }

    if (record.metadata && Object.keys(record.metadata).length > 0) {
      lines.push('  metadata:');
      lines.push(this.indentBlock(JSON.stringify(record.metadata, null, 2), 4));
    }

    if (record.error) {
      lines.push('  error:');
      lines.push(this.indentBlock(JSON.stringify(record.error, null, 2), 4));
    }

    return lines.join('\n');
  }

  private asPair(key: string, value: string | undefined): string | undefined {
    return value ? `${key}=${value}` : undefined;
  }

  private asValue(value: boolean | number | undefined): string | undefined {
    return value === undefined ? undefined : String(value);
  }

  private joinEntity(
    entityType: string | undefined,
    entityId: string | undefined,
  ): string | undefined {
    if (!entityType && !entityId) {
      return undefined;
    }

    return [entityType, entityId].filter(Boolean).join(':');
  }

  private indentBlock(value: string, spaces: number): string {
    const indent = ' '.repeat(spaces);
    return value
      .split('\n')
      .map((line) => `${indent}${line}`)
      .join('\n');
  }
}

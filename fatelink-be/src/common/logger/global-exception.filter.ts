import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { Response } from 'express';
import { APP_ERROR_MAP } from '../errors/app-error-map';
import { AppError } from '../errors/app-error';
import { AppLoggerService } from './logger.service';
import { RequestWithContext } from './log.types';

@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  constructor(private readonly logger: AppLoggerService) {}

  catch(exception: unknown, host: ArgumentsHost): void {
    const http = host.switchToHttp();
    const response = http.getResponse<Response>();
    const request = http.getRequest<RequestWithContext>();

    if (exception instanceof AppError) {
      const definition = APP_ERROR_MAP[exception.code];
      const status = definition?.status ?? HttpStatus.BAD_REQUEST;
      const message = this.resolveAppErrorMessage(
        exception,
        definition?.message,
      );
      const logContext = {
        message: `${request.method} ${request.originalUrl ?? request.url}`,
        user_id: exception.metadata?.userId,
        actor_id: exception.metadata?.actorId,
        entity_type: exception.metadata?.entityType,
        entity_id: exception.metadata?.entityId,
        error_code: exception.code,
        error_message: message,
        retryable: exception.metadata?.retryable,
        metadata: {
          domain: exception.metadata?.domain,
          layer: exception.metadata?.layer,
          kind: exception.metadata?.kind,
          source: exception.metadata?.source,
          provider: exception.metadata?.provider,
          status_code: status,
          path: request.originalUrl ?? request.url,
          details: exception.details,
        },
      };

      if (status >= 500) {
        this.logger.errorEvent('http_request_failed', exception, logContext);
      } else {
        this.logger.warnEvent('http_request_failed', logContext);
      }

      response.status(status).json({
        code: exception.code,
        message,
        details: exception.details,
        path: request.originalUrl ?? request.url,
        request_id: request.requestId,
        trace_id: request.traceId,
        timestamp: new Date().toISOString(),
      });
      return;
    }

    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const errorMessage = this.resolveHttpErrorMessage(
        exception.getResponse(),
        exception.message,
      );
      const logContext = {
        message: `${request.method} ${request.originalUrl ?? request.url}`,
        error_code: `HTTP_${status}`,
        error_message: Array.isArray(errorMessage)
          ? errorMessage.join('; ')
          : errorMessage,
        metadata: {
          status_code: status,
          path: request.originalUrl ?? request.url,
        },
      };

      if (status >= 500) {
        this.logger.errorEvent('http_request_failed', exception, logContext);
      } else {
        this.logger.warnEvent('http_request_failed', logContext);
      }

      response.status(status).json({
        code: `HTTP_${status}`,
        message: errorMessage,
        path: request.originalUrl ?? request.url,
        request_id: request.requestId,
        trace_id: request.traceId,
        timestamp: new Date().toISOString(),
      });
      return;
    }

    const message =
      exception instanceof Error ? exception.message : 'Internal server error';

    this.logger.errorEvent('http_request_failed', exception, {
      message: `${request.method} ${request.originalUrl ?? request.url}`,
      error_code: 'INTERNAL_SERVER_ERROR',
      error_message: message,
      retryable: false,
      metadata: {
        status_code: HttpStatus.INTERNAL_SERVER_ERROR,
        path: request.originalUrl ?? request.url,
      },
    });

    response.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
      code: 'INTERNAL_SERVER_ERROR',
      message: 'Internal server error',
      path: request.originalUrl ?? request.url,
      request_id: request.requestId,
      trace_id: request.traceId,
      timestamp: new Date().toISOString(),
    });
  }

  private resolveHttpErrorMessage(
    body: string | object,
    fallback: string,
  ): string | string[] {
    if (typeof body === 'string') {
      return body;
    }

    if (!('message' in body)) {
      return fallback;
    }

    if (Array.isArray(body.message)) {
      return body.message.filter(
        (value): value is string => typeof value === 'string',
      );
    }

    return typeof body.message === 'string' ? body.message : fallback;
  }

  private resolveAppErrorMessage(
    error: AppError,
    fallbackMessage: string | undefined,
  ): string {
    if (!error.message || error.message === error.code) {
      return fallbackMessage ?? 'Application error';
    }

    return error.message;
  }
}

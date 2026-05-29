import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Response } from 'express';
import {
  AppError,
  AppErrorMetadata
} from '../errors/app-error';
import { APP_ERROR_MAP } from '../errors/app-error-map';
import { RequestWithContext } from '../logger/log.types';

@Catch()
export class ApiExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(ApiExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<RequestWithContext>();
    const requestContext = `${request.method} ${request.url}`;
    const requestId = request.requestId;

    if (exception instanceof AppError) {
      const definition = APP_ERROR_MAP[exception.code];
      const resolvedMessage = this.resolveAppErrorMessage(
        exception,
        definition,
      );
      const classification = this.resolveAppErrorMetadata(exception);
      this.logger.warn(
        this.formatLogPayload({
          type: 'app_error',
          domain: classification.domain,
          layer: classification.layer,
          kind: classification.kind,
          source: classification.source,
          provider: classification.provider,
          code: exception.code,
          message: resolvedMessage,
          details: exception.details,
          cause: this.resolveCauseSummary(exception.cause),
          request: requestContext,
          requestId,
        }),
      );

      response.status(definition.status).json({
        code: exception.code,
        message: resolvedMessage,
        details: exception.details,
        path: request.url,
        requestId,
        timestamp: new Date().toISOString(),
      });
      return;
    }

    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const body = exception.getResponse();
      this.logger.warn(
        this.formatLogPayload({
          type: 'http_exception',
          status,
          message: this.resolveHttpErrorMessage(body, exception.message),
          request: requestContext,
          requestId,
        }),
      );

      response.status(status).json({
        code: this.resolveHttpErrorCode(status),
        message: this.resolveHttpErrorMessage(body, exception.message),
        path: request.url,
        requestId,
        timestamp: new Date().toISOString(),
      });
      return;
    }

    const error = exception instanceof Error ? exception : undefined;
    this.logger.error(
      this.formatLogPayload({
        type: 'unhandled_exception',
        message: error?.message ?? 'Unknown error',
        request: requestContext,
        requestId,
      }),
      error?.stack,
    );

    response.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
      code: 'INTERNAL_SERVER_ERROR',
      message: 'Internal server error',
      path: request.url,
      requestId,
      timestamp: new Date().toISOString(),
    });
  }

  private resolveHttpErrorCode(status: number): string {
    return `HTTP_${status}`;
  }

  private resolveHttpErrorMessage(
    body: string | object,
    fallbackMessage: string,
  ): string | string[] {
    if (typeof body === 'string') {
      return body;
    }

    if (!('message' in body)) {
      return fallbackMessage;
    }

    if (Array.isArray(body.message)) {
      return body.message.filter(
        (message): message is string => typeof message === 'string',
      );
    }

    if (typeof body.message === 'string') {
      return body.message;
    }

    return fallbackMessage;
  }

  private resolveAppErrorMessage(
    exception: AppError,
    definition: { message: string },
  ): string {
    if (!exception.message || exception.message === exception.code) {
      return definition.message;
    }

    return exception.message;
  }

  private formatLogPayload(payload: Record<string, unknown>): string {
    return JSON.stringify(payload, null, 2);
  }

  private resolveCauseSummary(cause: unknown): string | undefined {
    if (cause instanceof Error) {
      return cause.message;
    }

    if (typeof cause === 'string') {
      return cause;
    }

    return undefined;
  }

  private resolveAppErrorMetadata(exception: AppError): AppErrorMetadata {
    const fallback = this.inferAppErrorMetadata(exception.code);

    return {
      domain: exception.metadata?.domain ?? fallback.domain,
      layer: exception.metadata?.layer ?? fallback.layer,
      kind: exception.metadata?.kind ?? fallback.kind,
      source: exception.metadata?.source ?? fallback.source,
      provider: exception.metadata?.provider ?? fallback.provider,
    };
  }

  private inferAppErrorMetadata(code: string): AppErrorMetadata {
    if (code.startsWith('AUTH_GOOGLE_')) {
      return {
        domain: 'auth',
        layer: 'external_api',
        kind: 'integration',
        source: 'GoogleTokenService.verifyIdToken',
        provider: 'google',
      };
    }

    if (code.startsWith('AUTH_REFRESH_')) {
      return {
        domain: 'auth',
        layer: 'service',
        kind: 'business',
        source: 'AuthTokenService.refreshTokenPair',
        provider: 'jwt',
      };
    }

    if (code.startsWith('AUTH_SESSION_')) {
      return {
        domain: 'auth',
        layer: 'repository',
        kind: 'infrastructure',
        source: 'AuthTokenService.issueTokenPair',
        provider: 'mongodb',
      };
    }

    if (code.startsWith('AUTH_')) {
      return {
        domain: 'auth',
        layer: 'service',
        kind: 'business',
        source: 'auth',
        provider: 'internal',
      };
    }

    return {
      domain: 'unknown',
      layer: 'unknown',
      kind: 'unexpected',
      source: 'unknown',
      provider: 'unknown',
    };
  }
}

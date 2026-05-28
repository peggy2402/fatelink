import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { AppError } from '../errors/app-error';
import { APP_ERROR_MAP } from '../errors/app-error-map';

@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    if (exception instanceof AppError) {
      const definition = APP_ERROR_MAP[exception.code];

      response.status(definition.status).json({
        code: exception.code,
        message: exception.message || definition.message,
        details: exception.details,
        path: request.url,
        timestamp: new Date().toISOString(),
      });
      return;
    }

    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const body = exception.getResponse();

      response.status(status).json({
        code: this.resolveHttpErrorCode(status),
        message: this.resolveHttpErrorMessage(body, exception.message),
        path: request.url,
        timestamp: new Date().toISOString(),
      });
      return;
    }

    response.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
      code: 'INTERNAL_SERVER_ERROR',
      message: 'Internal server error',
      path: request.url,
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
}

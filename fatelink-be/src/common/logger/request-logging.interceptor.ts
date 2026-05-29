import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Response } from 'express';
import { Observable } from 'rxjs';
import { AppLoggerService } from './logger.service';
import { RequestContextService } from './request-context.service';
import { RequestWithContext } from './log.types';

@Injectable()
export class RequestLoggingInterceptor implements NestInterceptor {
  constructor(
    private readonly logger: AppLoggerService,
    private readonly requestContext: RequestContextService,
  ) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    if (context.getType() !== 'http') {
      return next.handle();
    }

    const http = context.switchToHttp();
    const request = http.getRequest<RequestWithContext>();
    const response = http.getResponse<Response>();
    const startedAt = process.hrtime.bigint();

    response.once('finish', () => {
      this.logger.assignRequestUser(request);
      this.requestContext.assignUser(request.user);

      const durationMs =
        Number(process.hrtime.bigint() - startedAt) / 1_000_000;
      const statusCode = response.statusCode;
      const level = statusCode >= 400 ? 'warn' : 'info';

      const metadata = {
        method: request.method,
        path: request.originalUrl ?? request.url,
        route: request.route?.path,
        status_code: statusCode,
        ip: this.resolveIp(request),
        user_agent: request.get('user-agent'),
      };

      this.logger.logEvent(level, 'http_request_completed', {
        message: `${request.method} ${request.originalUrl ?? request.url}`,
        duration_ms: durationMs,
        metadata,
      });
    });

    return next.handle();
  }

  private resolveIp(request: RequestWithContext): string | undefined {
    const forwardedFor = request.headers['x-forwarded-for'];
    if (typeof forwardedFor === 'string') {
      return forwardedFor.split(',')[0]?.trim();
    }

    return request.ip;
  }
}

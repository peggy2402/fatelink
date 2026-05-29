import { Global, Module } from '@nestjs/common';
import { APP_FILTER, APP_INTERCEPTOR } from '@nestjs/core';
import { GlobalExceptionFilter } from './global-exception.filter';
import { AppLoggerService } from './logger.service';
import { RequestLoggingInterceptor } from './request-logging.interceptor';
import { RequestContextService } from './request-context.service';
import { SensitiveDataRedactor } from './sensitive-data-redactor';

@Global()
@Module({
  providers: [
    SensitiveDataRedactor,
    RequestContextService,
    AppLoggerService,
    {
      provide: APP_INTERCEPTOR,
      useClass: RequestLoggingInterceptor,
    },
    {
      provide: APP_FILTER,
      useClass: GlobalExceptionFilter,
    },
  ],
  exports: [SensitiveDataRedactor, RequestContextService, AppLoggerService],
})
export class LoggerModule {}

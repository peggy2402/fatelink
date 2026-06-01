import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpStatus,
} from '@nestjs/common';
import { ApplicationError } from '@shared/errors/application-error';
import type { Response } from 'express';

const statusByCode: Record<string, HttpStatus> = {
  BAD_REQUEST: HttpStatus.BAD_REQUEST,
  CONFLICT: HttpStatus.CONFLICT,
  FORBIDDEN: HttpStatus.FORBIDDEN,
  UNAUTHORIZED: HttpStatus.UNAUTHORIZED,
  NOT_FOUND: HttpStatus.NOT_FOUND,
  INTERNAL: HttpStatus.INTERNAL_SERVER_ERROR,
};

@Catch(ApplicationError)
export class ApplicationErrorFilter implements ExceptionFilter {
  catch(exception: ApplicationError, host: ArgumentsHost) {
    const response = host.switchToHttp().getResponse<Response>();
    const status =
      statusByCode[exception.code] ?? HttpStatus.INTERNAL_SERVER_ERROR;

    response.status(status).json({
      statusCode: status,
      message: exception.message,
      error: exception.code,
    });
  }
}

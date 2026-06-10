import type { ErrorCategory, ErrorCode } from './error-codes';
import { ERROR_CATEGORY, ERROR_CODES } from './error-codes';

export class ApplicationError extends Error {
  constructor(
    message: string,
    readonly category: ErrorCategory,
    readonly errorCode: ErrorCode = ERROR_CODES.COMMON_INTERNAL_ERROR,
  ) {
    super(message);
    this.name = new.target.name;
  }
}

export class UnauthorizedApplicationError extends ApplicationError {
  constructor(message: string, errorCode?: ErrorCode) {
    super(message, ERROR_CATEGORY.UNAUTHORIZED, errorCode);
  }
}

export class BadRequestApplicationError extends ApplicationError {
  constructor(message: string, errorCode?: ErrorCode) {
    super(message, ERROR_CATEGORY.BAD_REQUEST, errorCode);
  }
}

export class ForbiddenApplicationError extends ApplicationError {
  constructor(message: string, errorCode?: ErrorCode) {
    super(message, ERROR_CATEGORY.FORBIDDEN, errorCode);
  }
}

export class ConflictApplicationError extends ApplicationError {
  constructor(message: string, errorCode?: ErrorCode) {
    super(message, ERROR_CATEGORY.CONFLICT, errorCode);
  }
}

export class NotFoundApplicationError extends ApplicationError {
  constructor(message: string, errorCode?: ErrorCode) {
    super(message, ERROR_CATEGORY.NOT_FOUND, errorCode);
  }
}

export class InternalApplicationError extends ApplicationError {
  constructor(message: string, errorCode?: ErrorCode) {
    super(message, ERROR_CATEGORY.INTERNAL, errorCode);
  }
}

export class ApplicationError extends Error {
  constructor(
    message: string,
    readonly code: string,
  ) {
    super(message);
    this.name = new.target.name;
  }
}

export class UnauthorizedApplicationError extends ApplicationError {
  constructor(message: string) {
    super(message, 'UNAUTHORIZED');
  }
}

export class BadRequestApplicationError extends ApplicationError {
  constructor(message: string) {
    super(message, 'BAD_REQUEST');
  }
}

export class ForbiddenApplicationError extends ApplicationError {
  constructor(message: string) {
    super(message, 'FORBIDDEN');
  }
}

export class ConflictApplicationError extends ApplicationError {
  constructor(message: string) {
    super(message, 'CONFLICT');
  }
}

export class NotFoundApplicationError extends ApplicationError {
  constructor(message: string) {
    super(message, 'NOT_FOUND');
  }
}

export class InternalApplicationError extends ApplicationError {
  constructor(message: string) {
    super(message, 'INTERNAL');
  }
}

import { type ArgumentsHost, HttpStatus } from '@nestjs/common';
import {
  BadRequestApplicationError,
  ConflictApplicationError,
} from '@shared/errors/application-error';
import { ERROR_CODES } from '@shared/errors/error-codes';
import { ApplicationErrorFilter } from './application-error.filter';

describe('ApplicationErrorFilter', () => {
  const createHost = (response: { status: jest.Mock; json: jest.Mock }) =>
    ({
      switchToHttp: () => ({
        getResponse: () => response,
      }),
    }) as ArgumentsHost;

  it('maps BAD_REQUEST to 400', () => {
    const response = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };
    const filter = new ApplicationErrorFilter();

    filter.catch(
      new BadRequestApplicationError(
        'invalid payload',
        ERROR_CODES.AUTH_GOOGLE_TOKEN_REQUIRED,
      ),
      createHost(response),
    );

    expect(response.status).toHaveBeenCalledWith(HttpStatus.BAD_REQUEST);
    expect(response.json).toHaveBeenCalledWith(
      expect.objectContaining({
        error: 'BAD_REQUEST',
        errorCode: ERROR_CODES.AUTH_GOOGLE_TOKEN_REQUIRED,
      }),
    );
  });

  it('maps CONFLICT to 409', () => {
    const response = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };
    const filter = new ApplicationErrorFilter();

    filter.catch(
      new ConflictApplicationError(
        'already exists',
        ERROR_CODES.AUTH_EMAIL_ALREADY_REGISTERED,
      ),
      createHost(response),
    );

    expect(response.status).toHaveBeenCalledWith(HttpStatus.CONFLICT);
    expect(response.json).toHaveBeenCalledWith(
      expect.objectContaining({
        error: 'CONFLICT',
        errorCode: ERROR_CODES.AUTH_EMAIL_ALREADY_REGISTERED,
      }),
    );
  });
});

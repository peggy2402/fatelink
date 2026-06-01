import { type ArgumentsHost, HttpStatus } from '@nestjs/common';
import {
  BadRequestApplicationError,
  ConflictApplicationError,
} from '@shared/errors/application-error';
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
      new BadRequestApplicationError('invalid payload'),
      createHost(response),
    );

    expect(response.status).toHaveBeenCalledWith(HttpStatus.BAD_REQUEST);
  });

  it('maps CONFLICT to 409', () => {
    const response = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };
    const filter = new ApplicationErrorFilter();

    filter.catch(
      new ConflictApplicationError('already exists'),
      createHost(response),
    );

    expect(response.status).toHaveBeenCalledWith(HttpStatus.CONFLICT);
  });
});

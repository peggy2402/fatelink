import {
  ConflictApplicationError,
  UnauthorizedApplicationError,
} from '@shared/errors/application-error';
import { ERROR_CODES } from '@shared/errors/error-codes';
import { EmailAuthServiceImpl } from './email-auth.service.impl';
import { SecretHashService } from './secret-hash.service';

describe('EmailAuthServiceImpl', () => {
  it('creates a new email account with a hashed password', async () => {
    const userRepository = {
      findByEmail: jest.fn().mockResolvedValue(null),
      createProfileAccount: jest.fn().mockImplementation(async (input) => ({
        id: 'user-1',
        email: input.email,
      })),
    };
    const authIdentityRepository = {
      findByProvider: jest.fn().mockResolvedValue(null),
      upsertEmailCredential: jest.fn(),
    };

    const service = new EmailAuthServiceImpl(
      userRepository as never,
      authIdentityRepository as never,
      new SecretHashService(),
    );
    await service.register({
      email: 'user@example.com',
      password: 'secret123',
      name: 'User',
    });

    expect(userRepository.createProfileAccount).toHaveBeenCalled();
    expect(authIdentityRepository.upsertEmailCredential).toHaveBeenCalled();
    expect(
      authIdentityRepository.upsertEmailCredential.mock.calls[0][0]
        .passwordHash,
    ).toContain(':');
  });

  it('rejects duplicate registered email', async () => {
    const userRepository = {
      findByEmail: jest.fn().mockResolvedValue({
        id: 'user-1',
        email: 'user@example.com',
      }),
    };
    const authIdentityRepository = {
      findByProvider: jest.fn().mockResolvedValue({
        userId: 'user-1',
        secretHash: 'salt:hash',
      }),
    };

    const service = new EmailAuthServiceImpl(
      userRepository as never,
      authIdentityRepository as never,
      new SecretHashService(),
    );

    await expect(
      service.register({
        email: 'user@example.com',
        password: 'secret123',
      }),
    ).rejects.toBeInstanceOf(ConflictApplicationError);
  });

  it('authenticates a valid password and rejects invalid password', async () => {
    const seedRepository = {
      findByEmail: jest.fn().mockResolvedValue(null),
      createProfileAccount: jest.fn().mockImplementation(async (input) => ({
        id: 'user-1',
        email: input.email,
      })),
    };
    const seedIdentityRepository = {
      findByProvider: jest.fn().mockResolvedValue(null),
      upsertEmailCredential: jest.fn(),
    };
    const seedService = new EmailAuthServiceImpl(
      seedRepository as never,
      seedIdentityRepository as never,
      new SecretHashService(),
    );
    const created = await seedService.register({
      email: 'user@example.com',
      password: 'secret123',
    });
    const storedHash =
      seedIdentityRepository.upsertEmailCredential.mock.calls[0][0]
        .passwordHash;

    const userRepository = {
      findById: jest.fn().mockResolvedValue(created),
    };
    const authIdentityRepository = {
      findByProvider: jest.fn().mockResolvedValue({
        userId: 'user-1',
        secretHash: storedHash,
      }),
    };
    const service = new EmailAuthServiceImpl(
      userRepository as never,
      authIdentityRepository as never,
      new SecretHashService(),
    );

    await expect(
      service.authenticate({
        email: 'user@example.com',
        password: 'secret123',
      }),
    ).resolves.toEqual(created);
    await expect(
      service.authenticate({
        email: 'user@example.com',
        password: 'wrong-pass',
      }),
    ).rejects.toBeInstanceOf(UnauthorizedApplicationError);
  });

  it('rejects password registration for an existing user that already owns the email', async () => {
    const userRepository = {
      findByEmail: jest.fn().mockResolvedValue({
        id: 'user-1',
        email: 'user@example.com',
      }),
      createProfileAccount: jest.fn(),
    };
    const authIdentityRepository = {
      findByProvider: jest.fn().mockResolvedValue(null),
      upsertEmailCredential: jest.fn(),
    };
    const service = new EmailAuthServiceImpl(
      userRepository as never,
      authIdentityRepository as never,
      new SecretHashService(),
    );

    await expect(
      service.register({
        email: 'user@example.com',
        password: 'secret123',
      }),
    ).rejects.toMatchObject({
      errorCode: ERROR_CODES.AUTH_EMAIL_REGISTRATION_REQUIRES_VERIFICATION,
    });
    expect(userRepository.createProfileAccount).not.toHaveBeenCalled();
    expect(authIdentityRepository.upsertEmailCredential).not.toHaveBeenCalled();
  });

  it('rejects authentication when the linked user no longer exists', async () => {
    const secretHashService = new SecretHashService();
    const storedHash = secretHashService.hash('secret123');
    const userRepository = {
      findById: jest.fn().mockResolvedValue(null),
    };
    const authIdentityRepository = {
      findByProvider: jest.fn().mockResolvedValue({
        userId: 'user-1',
        secretHash: storedHash,
      }),
    };
    const service = new EmailAuthServiceImpl(
      userRepository as never,
      authIdentityRepository as never,
      secretHashService,
    );

    await expect(
      service.authenticate({
        email: 'user@example.com',
        password: 'secret123',
      }),
    ).rejects.toBeInstanceOf(UnauthorizedApplicationError);
  });
});

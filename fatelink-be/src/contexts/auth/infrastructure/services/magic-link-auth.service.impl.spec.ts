import type { ConfigService } from '@nestjs/config';
import {
  BadRequestApplicationError,
  UnauthorizedApplicationError,
} from '@shared/errors/application-error';
import { AUTH_ENV } from '@contexts/auth/infrastructure/config/auth-env';
import { MagicLinkAuthServiceImpl } from './magic-link-auth.service.impl';
import { SecretHashService } from './secret-hash.service';

describe('MagicLinkAuthServiceImpl', () => {
  const emailDeliveryService = {
    sendMagicLink: jest.fn().mockResolvedValue(undefined),
  };

  const configService = {
    get: jest.fn((key: string) => {
      if (key === AUTH_ENV.magicLinkExpiresInMinutes) {
        return '15';
      }
      if (key === AUTH_ENV.authExposeDebugChallenges) {
        return 'true';
      }
      if (key === AUTH_ENV.magicLinkBaseUrl) {
        return 'http://localhost:3000/magic-link';
      }
      return undefined;
    }),
  } as unknown as ConfigService;

  it('issues a magic link and exposes it in debug mode', async () => {
    const userRepository = {
      findByEmail: jest.fn(),
      createProfileAccount: jest.fn(),
    };
    const authChallengeRepository = {
      save: jest.fn().mockImplementation(async (input) => input),
    };
    const service = new MagicLinkAuthServiceImpl(
      userRepository as never,
      authChallengeRepository as never,
      configService,
      new SecretHashService(),
      emailDeliveryService as never,
    );

    const result = await service.requestLink({ email: 'user@example.com' });

    expect(authChallengeRepository.save).toHaveBeenCalled();
    expect(result.magicLink).toContain('token=');
  });

  it('consumes a valid magic link challenge', async () => {
    const seedRepository = {
      findByEmail: jest.fn(),
      createProfileAccount: jest.fn(),
    };
    const seedAuthChallengeRepository = {
      save: jest.fn().mockImplementation(async (input) => input),
    };
    const seedService = new MagicLinkAuthServiceImpl(
      seedRepository as never,
      seedAuthChallengeRepository as never,
      configService,
      new SecretHashService(),
      emailDeliveryService as never,
    );
    const issued = await seedService.requestLink({ email: 'user@example.com' });
    const encodedToken = decodeURIComponent(
      (issued.magicLink as string).split('token=')[1],
    );

    const userRepository = {
      findByEmail: jest.fn().mockResolvedValue({ id: 'user-1' }),
    };
    const authChallengeRepository = {
      consumeMagicLink: jest.fn().mockResolvedValue({
        secretHash:
          seedAuthChallengeRepository.save.mock.calls[0][0].secretHash,
        expiresAt: new Date(Date.now() + 60_000),
      }),
    };
    const service = new MagicLinkAuthServiceImpl(
      userRepository as never,
      authChallengeRepository as never,
      configService,
      new SecretHashService(),
      emailDeliveryService as never,
    );

    await expect(
      service.authenticate({ token: encodedToken }),
    ).resolves.toEqual({
      id: 'user-1',
    });
  });

  it('rejects an invalid magic link token', async () => {
    const userRepository = {
      findByEmail: jest.fn().mockResolvedValue(null),
    };
    const authChallengeRepository = {
      consumeMagicLink: jest.fn().mockResolvedValue(null),
    };
    const service = new MagicLinkAuthServiceImpl(
      userRepository as never,
      authChallengeRepository as never,
      configService,
      new SecretHashService(),
    );

    await expect(
      service.authenticate({ token: 'user%40example.com.invalid' }),
    ).rejects.toBeInstanceOf(UnauthorizedApplicationError);
  });

  it('rejects a malformed magic link token', async () => {
    const service = new MagicLinkAuthServiceImpl(
      {} as never,
      {} as never,
      configService,
      new SecretHashService(),
      emailDeliveryService as never,
    );

    await expect(
      service.authenticate({ token: 'malformed-token' }),
    ).rejects.toBeInstanceOf(BadRequestApplicationError);
  });

  it('creates a user when a valid magic link has no existing account', async () => {
    const secretHashService = new SecretHashService();
    const tokenSecret = 'valid-token-secret';
    const userRepository = {
      findByEmail: jest.fn().mockResolvedValue(null),
      createProfileAccount: jest.fn().mockResolvedValue({ id: 'user-new' }),
    };
    const authChallengeRepository = {
      consumeMagicLink: jest.fn().mockResolvedValue({
        secretHash: secretHashService.hash(tokenSecret),
        expiresAt: new Date(Date.now() + 60_000),
        metadata: { name: 'Magic User' },
      }),
    };
    const service = new MagicLinkAuthServiceImpl(
      userRepository as never,
      authChallengeRepository as never,
      configService,
      secretHashService,
      emailDeliveryService as never,
    );

    const result = await service.authenticate({
      token: `new%40example.com.${tokenSecret}`,
    });

    expect(userRepository.createProfileAccount).toHaveBeenCalledWith({
      email: 'new@example.com',
      name: 'Magic User',
      avatar: '',
    });
    expect(result).toEqual({ id: 'user-new' });
  });

  it('does not expose magic link by default when debug challenges are not configured', async () => {
    const safeConfigService = {
      get: jest.fn((key: string) => {
        if (key === AUTH_ENV.magicLinkExpiresInMinutes) {
          return '15';
        }
        if (key === AUTH_ENV.magicLinkBaseUrl) {
          return 'http://localhost:3000/magic-link';
        }
        return undefined;
      }),
    } as unknown as ConfigService;
    const service = new MagicLinkAuthServiceImpl(
      {} as never,
      {
        save: jest.fn().mockImplementation(async (input) => input),
      } as never,
      safeConfigService,
      new SecretHashService(),
      emailDeliveryService as never,
    );

    const result = await service.requestLink({ email: 'user@example.com' });

    expect(result.magicLink).toBeUndefined();
    expect(emailDeliveryService.sendMagicLink).toHaveBeenCalled();
  });
});

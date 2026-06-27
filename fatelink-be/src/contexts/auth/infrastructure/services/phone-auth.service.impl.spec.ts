import type { ConfigService } from '@nestjs/config';
import {
  BadRequestApplicationError,
  UnauthorizedApplicationError,
} from '@shared/errors/application-error';
import { AUTH_ENV } from '@contexts/auth/infrastructure/config/auth-env';
import { ERROR_CODES } from '@shared/errors/error-codes';
import { PhoneAuthServiceImpl } from './phone-auth.service.impl';
import { SecretHashService } from './secret-hash.service';

describe('PhoneAuthServiceImpl', () => {
  const phoneOtpDeliveryService = {
    sendOtp: jest.fn().mockResolvedValue(undefined),
  };

  const configService = {
    get: jest.fn((key: string) => {
      if (key === AUTH_ENV.phoneOtpExpiresInMinutes) {
        return '5';
      }
      if (key === AUTH_ENV.authExposeDebugChallenges) {
        return 'true';
      }
      return undefined;
    }),
  } as unknown as ConfigService;

  it('issues OTP and exposes it in debug mode', async () => {
    const userRepository = {
      createProfileAccount: jest.fn(),
    };
    const authIdentityRepository = {};
    const authChallengeRepository = {
      save: jest.fn().mockImplementation(async (input) => input),
    };
    const service = new PhoneAuthServiceImpl(
      userRepository as never,
      authIdentityRepository as never,
      authChallengeRepository as never,
      configService,
      new SecretHashService(),
      phoneOtpDeliveryService as never,
    );

    const result = await service.requestOtp({ phoneNumber: '+84901234567' });

    expect(authChallengeRepository.save).toHaveBeenCalled();
    expect(result.otpCode).toMatch(/^\d{6}$/);
  });

  it('consumes a valid OTP challenge', async () => {
    const seedRepository = {
      createProfileAccount: jest.fn(),
    };
    const seedAuthChallengeRepository = {
      save: jest.fn().mockImplementation(async (input) => input),
    };
    const seedService = new PhoneAuthServiceImpl(
      seedRepository as never,
      {} as never,
      seedAuthChallengeRepository as never,
      configService,
      new SecretHashService(),
      phoneOtpDeliveryService as never,
    );
    const issued = await seedService.requestOtp({
      phoneNumber: '+84901234567',
    });

    const userRepository = {
      findById: jest.fn().mockResolvedValue({ id: 'user-1' }),
    };
    const authIdentityRepository = {
      findByProvider: jest.fn().mockResolvedValue({ userId: 'user-1' }),
    };
    const authChallengeRepository = {
      find: jest.fn().mockResolvedValue({
        secretHash:
          seedAuthChallengeRepository.save.mock.calls[0][0].secretHash,
        expiresAt: new Date(Date.now() + 60_000),
      }),
      consume: jest.fn(),
    };
    const service = new PhoneAuthServiceImpl(
      userRepository as never,
      authIdentityRepository as never,
      authChallengeRepository as never,
      configService,
      new SecretHashService(),
      phoneOtpDeliveryService as never,
    );

    await expect(
      service.authenticate({
        phoneNumber: '+84901234567',
        otpCode: issued.otpCode as string,
      }),
    ).resolves.toEqual({ id: 'user-1' });
  });

  it('rejects expired or invalid OTP', async () => {
    const userRepository = {
      findById: jest.fn(),
    };
    const authIdentityRepository = {
      findByProvider: jest.fn().mockResolvedValue(null),
    };
    const authChallengeRepository = {
      find: jest.fn().mockResolvedValue({
        secretHash: 'salt:hash',
        expiresAt: new Date(Date.now() - 60_000),
      }),
    };
    const service = new PhoneAuthServiceImpl(
      userRepository as never,
      authIdentityRepository as never,
      authChallengeRepository as never,
      configService,
      new SecretHashService(),
    );

    await expect(
      service.authenticate({
        phoneNumber: '+84901234567',
        otpCode: '123456',
      }),
    ).rejects.toBeInstanceOf(UnauthorizedApplicationError);
  });

  it('locks OTP after too many failed attempts', async () => {
    const secretHashService = new SecretHashService();
    const authChallengeRepository = {
      find: jest.fn().mockResolvedValue({
        secretHash: secretHashService.hash('654321'),
        expiresAt: new Date(Date.now() + 60_000),
        attemptCount: 4,
        maxAttempts: 5,
      }),
      registerFailedAttempt: jest.fn().mockResolvedValue({
        lockedAt: new Date(),
      }),
    };
    const service = new PhoneAuthServiceImpl(
      {} as never,
      {} as never,
      authChallengeRepository as never,
      configService,
      secretHashService,
      phoneOtpDeliveryService as never,
    );

    await expect(
      service.authenticate({
        phoneNumber: '+84901234567',
        otpCode: '123456',
      }),
    ).rejects.toMatchObject({
      errorCode: ERROR_CODES.AUTH_PHONE_OTP_ATTEMPTS_EXCEEDED,
    });
  });

  it('creates a new user and links phone identity when no identity exists', async () => {
    const secretHashService = new SecretHashService();
    const userRepository = {
      createProfileAccount: jest.fn().mockResolvedValue({ id: 'user-new' }),
      findById: jest.fn(),
    };
    const authIdentityRepository = {
      findByProvider: jest.fn().mockResolvedValue(null),
      linkPhoneIdentity: jest.fn(),
    };
    const authChallengeRepository = {
      find: jest.fn().mockResolvedValue({
        secretHash: secretHashService.hash('123456'),
        expiresAt: new Date(Date.now() + 60_000),
        metadata: { name: 'Phone User' },
      }),
      consume: jest.fn(),
    };
    const service = new PhoneAuthServiceImpl(
      userRepository as never,
      authIdentityRepository as never,
      authChallengeRepository as never,
      configService,
      secretHashService,
      phoneOtpDeliveryService as never,
    );

    const result = await service.authenticate({
      phoneNumber: '+84901234567',
      otpCode: '123456',
    });

    expect(userRepository.createProfileAccount).toHaveBeenCalled();
    expect(authIdentityRepository.linkPhoneIdentity).toHaveBeenCalledWith({
      userId: 'user-new',
      phoneNumber: '+84901234567',
    });
    expect(result).toEqual({ id: 'user-new' });
  });

  it('rejects when phone identity exists but linked user is missing', async () => {
    const secretHashService = new SecretHashService();
    const userRepository = {
      findById: jest.fn().mockResolvedValue(null),
    };
    const authIdentityRepository = {
      findByProvider: jest.fn().mockResolvedValue({ userId: 'user-1' }),
    };
    const authChallengeRepository = {
      find: jest.fn().mockResolvedValue({
        secretHash: secretHashService.hash('123456'),
        expiresAt: new Date(Date.now() + 60_000),
      }),
      consume: jest.fn(),
    };
    const service = new PhoneAuthServiceImpl(
      userRepository as never,
      authIdentityRepository as never,
      authChallengeRepository as never,
      configService,
      secretHashService,
      phoneOtpDeliveryService as never,
    );

    await expect(
      service.authenticate({
        phoneNumber: '+84901234567',
        otpCode: '123456',
      }),
    ).rejects.toBeInstanceOf(BadRequestApplicationError);
  });

  it('does not expose OTP by default when debug challenges are not configured', async () => {
    const safeConfigService = {
      get: jest.fn((key: string) => {
        if (key === AUTH_ENV.phoneOtpExpiresInMinutes) {
          return '5';
        }
        return undefined;
      }),
    } as unknown as ConfigService;
    const service = new PhoneAuthServiceImpl(
      {} as never,
      {} as never,
      {
        save: jest.fn().mockImplementation(async (input) => input),
      } as never,
      safeConfigService,
      new SecretHashService(),
      phoneOtpDeliveryService as never,
    );

    const result = await service.requestOtp({ phoneNumber: '+84901234567' });

    expect(result.otpCode).toBeUndefined();
    expect(phoneOtpDeliveryService.sendOtp).toHaveBeenCalled();
  });
});

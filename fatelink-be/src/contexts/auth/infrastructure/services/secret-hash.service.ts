import { randomBytes, scryptSync, timingSafeEqual } from 'crypto';

export class SecretHashService {
  hash(value: string) {
    const salt = randomBytes(16).toString('hex');
    const hash = scryptSync(value, salt, 64).toString('hex');
    return `${salt}:${hash}`;
  }

  verify(value: string, storedHash: string) {
    const [salt, hash] = storedHash.split(':');
    const derived = scryptSync(value, salt, 64);
    return timingSafeEqual(Buffer.from(hash, 'hex'), derived);
  }
}

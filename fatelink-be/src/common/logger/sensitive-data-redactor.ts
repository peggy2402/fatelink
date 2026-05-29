import { Injectable } from '@nestjs/common';

const REDACTED_VALUE = '[REDACTED]';
const MASKED_EMAIL_VALUE = '[MASKED_EMAIL]';
const MASKED_PHONE_VALUE = '[MASKED_PHONE]';
const OMITTED_BINARY_VALUE = '[OMITTED_BINARY]';
const OMITTED_BODY_VALUE = '[OMITTED_BODY]';
const TRUNCATED_VALUE = '[TRUNCATED]';

const SENSITIVE_KEY_PATTERN =
  /(password|passwd|pwd|access[_-]?token|refresh[_-]?token|authorization|cookie|set-cookie|otp|private[_-]?key|secret|api[_-]?key|client[_-]?secret|credit[_-]?card|card[_-]?number|cvv|cvc|pin)/i;
const EMAIL_KEY_PATTERN = /(email|mail)/i;
const PHONE_KEY_PATTERN = /(phone|mobile|msisdn|tel)/i;
const BODY_KEY_PATTERN =
  /(raw[_-]?body|request[_-]?body|response[_-]?body|body)/i;
const FILE_KEY_PATTERN =
  /(file|buffer|content|base64|image|avatar|document|attachment)/i;

@Injectable()
export class SensitiveDataRedactor {
  redact<T>(value: T): T {
    return this.sanitizeValue(value, undefined, 0, new WeakSet()) as T;
  }

  maskEmail(email: string): string {
    const [localPart, domain] = email.split('@');
    if (!localPart || !domain) {
      return MASKED_EMAIL_VALUE;
    }

    const visible = localPart.slice(0, 2);
    return `${visible}***@${domain}`;
  }

  maskPhone(phone: string): string {
    const digits = phone.replace(/\D/g, '');
    if (digits.length < 4) {
      return MASKED_PHONE_VALUE;
    }

    return `${digits.slice(0, 2)}***${digits.slice(-2)}`;
  }

  private sanitizeValue(
    value: unknown,
    key: string | undefined,
    depth: number,
    seen: WeakSet<object>,
  ): unknown {
    if (value === null || value === undefined) {
      return value;
    }

    if (key && SENSITIVE_KEY_PATTERN.test(key)) {
      return REDACTED_VALUE;
    }

    if (typeof value === 'string') {
      return this.sanitizeString(value, key);
    }

    if (typeof value === 'number' || typeof value === 'boolean') {
      return value;
    }

    if (typeof value === 'bigint') {
      return value.toString();
    }

    if (value instanceof Date) {
      return value.toISOString();
    }

    if (Buffer.isBuffer(value)) {
      return OMITTED_BINARY_VALUE;
    }

    if (Array.isArray(value)) {
      if (depth >= 4) {
        return `[ARRAY(${value.length})]`;
      }

      return value.map((item) =>
        this.sanitizeValue(item, key, depth + 1, seen),
      );
    }

    if (typeof value === 'object') {
      if (seen.has(value)) {
        return '[CIRCULAR]';
      }

      if (depth >= 4) {
        return '[OBJECT]';
      }

      seen.add(value);

      const entries = Object.entries(value as Record<string, unknown>).map(
        ([entryKey, entryValue]) => [
          entryKey,
          this.sanitizeValue(entryValue, entryKey, depth + 1, seen),
        ],
      );

      seen.delete(value);
      return Object.fromEntries(entries);
    }

    return String(value);
  }

  private sanitizeString(value: string, key: string | undefined): string {
    if (this.looksLikeBase64(value) || value.length > 2048) {
      return `${TRUNCATED_VALUE}:${value.length}`;
    }

    if (key && BODY_KEY_PATTERN.test(key)) {
      return OMITTED_BODY_VALUE;
    }

    if (key && FILE_KEY_PATTERN.test(key) && value.length > 256) {
      return OMITTED_BINARY_VALUE;
    }

    if (key && EMAIL_KEY_PATTERN.test(key)) {
      return this.maskEmail(value);
    }

    if (key && PHONE_KEY_PATTERN.test(key)) {
      return this.maskPhone(value);
    }

    return value;
  }

  private looksLikeBase64(value: string): boolean {
    if (value.length < 256 || value.length % 4 !== 0) {
      return false;
    }

    return /^[A-Za-z0-9+/=]+$/.test(value);
  }
}

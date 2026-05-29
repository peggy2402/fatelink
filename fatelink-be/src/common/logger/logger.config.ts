import { LoggerRuntimeConfig, LogLevel } from './log.types';

export const LOGGER_ENV_KEYS = {
  service: 'LOG_SERVICE_NAME',
  env: 'NODE_ENV',
  version: 'APP_VERSION',
  level: 'LOG_LEVEL',
  includeStack: 'LOG_INCLUDE_STACK',
  prettyPrint: 'LOG_PRETTY_PRINT',
  prettyFormat: 'LOG_PRETTY_FORMAT',
} as const;

const DEFAULT_SERVICE_NAME = 'fatelink-be';
const DEFAULT_VERSION = 'unknown';

export function resolveLoggerRuntimeConfig(): LoggerRuntimeConfig {
  const env = process.env[LOGGER_ENV_KEYS.env] ?? 'development';
  const defaultLevel: LogLevel = env === 'production' ? 'info' : 'debug';

  return {
    service: process.env[LOGGER_ENV_KEYS.service] ?? DEFAULT_SERVICE_NAME,
    env,
    version:
      process.env[LOGGER_ENV_KEYS.version] ??
      process.env.npm_package_version ??
      DEFAULT_VERSION,
    level: resolveLogLevel(process.env[LOGGER_ENV_KEYS.level], defaultLevel),
    include_stack: resolveBoolean(
      process.env[LOGGER_ENV_KEYS.includeStack],
      env !== 'production',
    ),
    pretty_print: resolveBoolean(
      process.env[LOGGER_ENV_KEYS.prettyPrint],
      env !== 'production',
    ),
    pretty_format: resolvePrettyFormat(
      process.env[LOGGER_ENV_KEYS.prettyFormat],
      'human',
    ),
  };
}

function resolveLogLevel(
  value: string | undefined,
  fallback: LogLevel,
): LogLevel {
  if (
    value === 'debug' ||
    value === 'info' ||
    value === 'warn' ||
    value === 'error' ||
    value === 'fatal'
  ) {
    return value;
  }

  return fallback;
}

function resolveBoolean(value: string | undefined, fallback: boolean): boolean {
  if (value === undefined) {
    return fallback;
  }

  return ['1', 'true', 'yes', 'on'].includes(value.toLowerCase());
}

function resolvePrettyFormat(
  value: string | undefined,
  fallback: 'human' | 'json' | 'text',
): 'human' | 'json' | 'text' {
  if (value === 'human' || value === 'json' || value === 'text') {
    return value;
  }

  return fallback;
}

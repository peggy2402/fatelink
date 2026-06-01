// @ts-check
import eslint from '@eslint/js';
import eslintPluginPrettierRecommended from 'eslint-plugin-prettier/recommended';
import globals from 'globals';
import { dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import tseslint from 'typescript-eslint';

const tsconfigRootDir = dirname(fileURLToPath(import.meta.url));

const architectureBoundaryRules = {
  'no-restricted-imports': [
    'error',
    {
      patterns: [
        {
          group: ['@contexts/*/presentation/*', '@shared/presentation/*'],
          message: 'Presentation dependencies must not leak into inner layers.',
        },
      ],
    },
  ],
};

export default tseslint.config(
  {
    ignores: [
      'dist/**',
      'coverage/**',
      'node_modules/**',
      'webpack-hmr.config.js',
      'eslint.config.mjs',
    ],
  },
  eslint.configs.recommended,
  ...tseslint.configs.recommendedTypeChecked,
  eslintPluginPrettierRecommended,
  {
    files: ['**/*.ts'],
    languageOptions: {
      globals: {
        ...globals.node,
      },
      sourceType: 'module',
      parserOptions: {
        projectService: true,
        tsconfigRootDir,
      },
    },
    rules: {
      '@typescript-eslint/consistent-type-imports': [
        'error',
        { prefer: 'type-imports', fixStyle: 'inline-type-imports' },
      ],
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/no-floating-promises': 'error',
      '@typescript-eslint/no-misused-promises': [
        'error',
        { checksVoidReturn: false },
      ],
      '@typescript-eslint/no-unsafe-argument': 'warn',
      '@typescript-eslint/no-unsafe-assignment': 'warn',
      '@typescript-eslint/no-unsafe-call': 'warn',
      '@typescript-eslint/no-unsafe-member-access': 'warn',
      '@typescript-eslint/no-unsafe-return': 'warn',
      '@typescript-eslint/no-unused-vars': [
        'warn',
        {
          argsIgnorePattern: '^_',
          caughtErrorsIgnorePattern: '^_',
          destructuredArrayIgnorePattern: '^_',
          varsIgnorePattern: '^_',
        },
      ],
      '@typescript-eslint/only-throw-error': 'off',
      '@typescript-eslint/require-await': 'off',
      curly: ['error', 'all'],
      eqeqeq: ['error', 'always'],
      'no-console': ['warn', { allow: ['warn', 'error'] }],
      'no-empty': ['warn', { allowEmptyCatch: true }],
      'no-useless-catch': 'warn',
      'object-shorthand': ['error', 'always'],
      'prefer-const': 'error',
      'prettier/prettier': ['error', { endOfLine: 'auto' }],
    },
  },
  {
    files: ['src/contexts/**/domain/**/*.ts'],
    rules: {
      ...architectureBoundaryRules,
      'no-restricted-imports': [
        'error',
        {
          patterns: [
            {
              group: ['@nestjs/*'],
              message: 'Domain layer must stay framework-agnostic.',
            },
            {
              group: [
                '@contexts/*/infrastructure/*',
                '@contexts/*/presentation/*',
                '@shared/infrastructure/*',
                '@shared/presentation/*',
              ],
              message: 'Domain layer may only depend on domain/shared-kernel abstractions.',
            },
          ],
        },
      ],
    },
  },
  {
    files: ['src/contexts/**/application/**/*.ts'],
    rules: {
      ...architectureBoundaryRules,
      'no-restricted-imports': [
        'error',
        {
          patterns: [
            {
              group: ['@nestjs/*'],
              message: 'Application layer must not depend on NestJS directly.',
            },
            {
              group: [
                '@contexts/*/presentation/*',
                '@contexts/*/infrastructure/*',
                '@shared/presentation/*',
              ],
              message: 'Application layer must depend on ports/contracts, not adapters.',
            },
          ],
        },
      ],
    },
  },
  {
    files: ['**/*.spec.ts', 'test/**/*.ts'],
    languageOptions: {
      globals: {
        ...globals.node,
        ...globals.jest,
      },
    },
    rules: {
      '@typescript-eslint/no-explicit-any': 'off',
      '@typescript-eslint/no-unsafe-argument': 'off',
      '@typescript-eslint/no-unsafe-assignment': 'off',
      '@typescript-eslint/no-unsafe-call': 'off',
      '@typescript-eslint/no-unsafe-member-access': 'off',
      '@typescript-eslint/no-unsafe-return': 'off',
      '@typescript-eslint/unbound-method': 'off',
      'no-console': 'off',
    },
  },
);

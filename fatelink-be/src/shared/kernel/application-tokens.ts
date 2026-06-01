import { ADMIN_APPLICATION_TOKENS } from '@contexts/admin/composition/admin.tokens';
import { AI_APPLICATION_TOKENS } from '@contexts/ai/composition/ai.tokens';
import { AUTH_APPLICATION_TOKENS } from '@contexts/auth/composition/auth.tokens';
import { CHAT_APPLICATION_TOKENS } from '@contexts/chat/composition/chat.tokens';
import { MATCHES_APPLICATION_TOKENS } from '@contexts/matching/composition/matches.tokens';
import { MATCHMAKING_APPLICATION_TOKENS } from '@contexts/matching/composition/matchmaking.tokens';
import { SUPPORT_APPLICATION_TOKENS } from '@contexts/support/composition/support.tokens';
import { USERS_APPLICATION_TOKENS } from '@contexts/users/composition/users.tokens';

/**
 * @deprecated Use context-local token constants instead, for example
 * `AUTH_APPLICATION_TOKENS`, `CHAT_APPLICATION_TOKENS`, or `USERS_APPLICATION_TOKENS`.
 * This aggregate is kept only as a compatibility layer for legacy imports.
 */
export const APPLICATION_TOKENS = {
  admin: ADMIN_APPLICATION_TOKENS,
  ai: AI_APPLICATION_TOKENS,
  chat: CHAT_APPLICATION_TOKENS,
  auth: AUTH_APPLICATION_TOKENS,
  matches: MATCHES_APPLICATION_TOKENS,
  matchmaking: MATCHMAKING_APPLICATION_TOKENS,
  support: SUPPORT_APPLICATION_TOKENS,
  users: USERS_APPLICATION_TOKENS,
} as const;

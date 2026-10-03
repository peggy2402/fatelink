import type { EmotionVector } from '@shared/kernel/emotion-vector';

export interface MatchCandidate {
  id: string;
  displayName: string;
  latestEmotion: string;
  bio: string;
  emotions?: EmotionVector;
  personality?: number[];
  tags?: string[];
  avatar?: string;
  moodIcon?: string;
  desiredVibe?: string;
  likesReceived?: number;
  likedUsers?: string[];
  isFaceLocked?: boolean;
  gender?: string;
  blockedUsers?: string[];
}

export interface MatchCandidateRepository {
  findCurrentUser(userId: string): Promise<MatchCandidate | null>;
  findOtherCandidates(userId: string): Promise<MatchCandidate[]>;
}

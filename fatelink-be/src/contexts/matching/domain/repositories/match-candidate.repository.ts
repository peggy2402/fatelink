import type { EmotionVector } from '@shared/kernel/emotion-vector';

export interface MatchCandidate {
  id: string;
  displayName: string;
  latestEmotion: string;
  bio: string;
  emotions?: EmotionVector;
  personality?: number[];
}

export interface MatchCandidateRepository {
  findCurrentUser(userId: string): Promise<MatchCandidate | null>;
  findOtherCandidates(userId: string): Promise<MatchCandidate[]>;
}

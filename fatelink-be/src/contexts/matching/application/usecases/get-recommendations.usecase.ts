import { type EmotionVector } from '@shared/kernel/emotion-vector';
import type {
  MatchCandidate,
  MatchCandidateRepository,
} from '@contexts/matching/domain/repositories/match-candidate.repository';

export class GetRecommendationsUseCase {
  constructor(
    private readonly matchCandidateRepository: MatchCandidateRepository,
  ) {}

  async execute(input: { userId: string }) {
    let currentUser: MatchCandidate | null = null;
    try {
      currentUser = await this.matchCandidateRepository.findCurrentUser(
        input.userId,
      );
    } catch (error) {
      void error;
    }

    if (!currentUser) {
      return this.getMockRecommendations();
    }

    const candidates = await this.matchCandidateRepository.findOtherCandidates(
      input.userId,
    );
    const recommendations = candidates.map((candidate) => {
      const distance = this.calculateEuclideanDistance(
        currentUser.personality || [5, 5, 5],
        candidate.personality || [5, 5, 5],
      );
      const similarityScore = Math.max(0, 100 - (distance / 17.32) * 100);
      const complementaryScore = this.calculateComplementaryScore(
        currentUser.emotions,
        candidate.emotions,
      );
      const finalScore = Math.round(
        complementaryScore * 0.6 + similarityScore * 0.4,
      );

      return {
        id: candidate.id,
        displayName: candidate.displayName || 'Nguoi Dau Ten',
        dominantEmotion: candidate.latestEmotion || 'Bi an',
        bio: candidate.bio || 'Chua co tieu su',
        matchingScore: finalScore,
      };
    });

    return recommendations.sort((a, b) => b.matchingScore - a.matchingScore);
  }

  private calculateEuclideanDistance(vecA: number[], vecB: number[]): number {
    if (!vecA || !vecB || vecA.length !== vecB.length) {
      return 0;
    }
    return Math.sqrt(
      vecA.reduce(
        (sum, value, index) => sum + Math.pow(value - vecB[index], 2),
        0,
      ),
    );
  }

  private calculateComplementaryScore(
    userAEmotions?: EmotionVector,
    userBEmotions?: EmotionVector,
  ): number {
    if (!userAEmotions || !userBEmotions) {
      return 50;
    }
    let score = 0;
    score += (userAEmotions.stress || 0) * (userBEmotions.calmness || 0) * 0.5;
    score += (userBEmotions.stress || 0) * (userAEmotions.calmness || 0) * 0.5;
    score +=
      (userAEmotions.loneliness || 0) * (userBEmotions.warmth || 0) * 0.5;
    score +=
      (userBEmotions.loneliness || 0) * (userAEmotions.warmth || 0) * 0.5;
    score +=
      (userAEmotions.sadness || 0) * (userBEmotions.happiness || 0) * 0.5;
    score +=
      (userBEmotions.sadness || 0) * (userAEmotions.happiness || 0) * 0.5;
    return Math.min(100, score);
  }

  private getMockRecommendations() {
    return [
      {
        id: 'mock-1',
        displayName: 'Trái tim Ấm áp',
        dominantEmotion: 'Bình yên',
        bio: 'Luôn ở đây lắng nghe bạn.',
        matchingScore: 92,
      },
      {
        id: 'mock-2',
        displayName: 'Năng lượng Tích cực',
        dominantEmotion: 'Vui vẻ',
        bio: 'Cuộc sống là những chuyến đi!',
        matchingScore: 78,
      },
    ];
  }
}

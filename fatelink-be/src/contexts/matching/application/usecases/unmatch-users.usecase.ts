import { NotFoundApplicationError } from '@shared/errors/application-error';
import type { MatchRepository } from '@contexts/matching/domain/repositories/match.repository';

export class UnmatchUsersUseCase {
  constructor(private readonly matchRepository: MatchRepository) {}

  async execute(input: { userId: string; partnerId: string }) {
    const deletedCount = await this.matchRepository.deleteMatchBetweenUsers(
      input.userId,
      input.partnerId,
    );
    if (deletedCount === 0) {
      throw new NotFoundApplicationError(
        'Không tìm thấy dữ liệu ghép đôi này.',
      );
    }
  }
}

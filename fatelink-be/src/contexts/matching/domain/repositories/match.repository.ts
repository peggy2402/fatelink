export interface MatchRepository {
  deleteMatchBetweenUsers(userId: string, partnerId: string): Promise<number>;
}

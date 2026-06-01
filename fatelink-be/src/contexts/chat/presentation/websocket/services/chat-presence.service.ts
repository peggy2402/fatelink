export class ChatPresenceService {
  private readonly activeUsers = new Map<string, Set<string>>();

  markOnline(userId: string, socketId: string): void {
    const sockets = this.activeUsers.get(userId) ?? new Set<string>();
    sockets.add(socketId);
    this.activeUsers.set(userId, sockets);
  }

  markOffline(userId: string, socketId: string): boolean {
    const sockets = this.activeUsers.get(userId);
    if (!sockets) {
      return true;
    }

    sockets.delete(socketId);
    if (sockets.size > 0) {
      return false;
    }

    this.activeUsers.delete(userId);
    return true;
  }

  getSocketId(userId: string): string | undefined {
    return this.getSocketIds(userId)[0];
  }

  getSocketIds(userId: string): string[] {
    return [...(this.activeUsers.get(userId) ?? [])];
  }

  isOnline(userId: string): boolean {
    return this.getSocketIds(userId).length > 0;
  }

  getManyStatuses(userIds: string[]): Record<string, boolean> {
    return userIds.reduce<Record<string, boolean>>((statuses, userId) => {
      statuses[userId] = this.isOnline(userId);
      return statuses;
    }, {});
  }
}

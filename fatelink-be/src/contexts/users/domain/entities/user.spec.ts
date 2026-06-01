import { User } from './user';

describe('User.applyTraitsUpdate', () => {
  it('mixes incoming traits into current state', () => {
    const user = User.rehydrate({
      id: 'user-1',
      email: 'user@example.com',
      name: 'User',
      avatar: '',
      googleId: 'google-1',
      latestEmotion: 'Cu',
      emotions: {
        stress: 10,
        loneliness: 0,
        sadness: 5,
        calmness: 10,
        warmth: 0,
        happiness: 5,
      },
      personality: [10, 0, 5],
      bio: '',
      fcmToken: '',
      tokenVersion: 0,
    });

    const result = user.applyTraitsUpdate({
      emotions: {
        stress: 0,
        warmth: 10,
      },
      personality: [0, 10, 5],
      latestEmotion: 'Moi',
    });

    expect(result).toEqual({
      emotions: {
        stress: 8,
        loneliness: 0,
        sadness: 5,
        calmness: 10,
        warmth: 2,
        happiness: 5,
      },
      personality: [9, 1, 5],
      latestEmotion: 'Moi',
    });
  });

  it('uses defaults when emotion or personality state is missing', () => {
    const user = User.rehydrate({
      id: 'user-2',
      email: 'user@example.com',
      name: 'User',
      avatar: '',
      googleId: 'google-2',
      latestEmotion: 'Binh thuong',
      emotions: undefined as never,
      personality: [] as number[],
      bio: '',
      fcmToken: '',
      tokenVersion: 0,
    });

    const result = user.applyTraitsUpdate({
      emotions: { happiness: 10 },
      personality: [10, 10, 10],
    });

    expect(result.emotions.happiness).toBe(6);
    expect(result.personality).toEqual([6, 6, 6]);
    expect(result.latestEmotion).toBe('Binh thuong');
  });
});

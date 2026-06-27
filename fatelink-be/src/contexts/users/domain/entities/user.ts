import { type EmotionVector } from '@shared/kernel/emotion-vector';

export class User {
  id?: string;
  email?: string;
  name!: string;
  displayName?: string;
  avatar!: string;
  latestEmotion!: string;
  emotions!: EmotionVector;
  personality!: number[];
  bio!: string;
  fcmToken!: string;

  static rehydrate(props: {
    id?: string;
    email?: string;
    name: string;
    displayName?: string;
    avatar: string;
    latestEmotion: string;
    emotions: EmotionVector;
    personality: number[];
    bio: string;
    fcmToken: string;
  }): User {
    const user = new User();
    Object.assign(user, props);
    return user;
  }

  applyTraitsUpdate(input: {
    emotions?: Partial<EmotionVector>;
    personality?: number[];
    latestEmotion?: string;
  }) {
    const currentEmotions = this.emotions || {
      stress: 5,
      loneliness: 5,
      sadness: 5,
      calmness: 5,
      warmth: 5,
      happiness: 5,
    };
    const currentPersonality =
      this.personality && this.personality.length === 3
        ? this.personality
        : [5, 5, 5];

    const weightE = 0.2;
    const weightP = 0.1;

    const emotions = {
      stress: this.mix(currentEmotions.stress, input.emotions?.stress, weightE),
      loneliness: this.mix(
        currentEmotions.loneliness,
        input.emotions?.loneliness,
        weightE,
      ),
      sadness: this.mix(
        currentEmotions.sadness,
        input.emotions?.sadness,
        weightE,
      ),
      calmness: this.mix(
        currentEmotions.calmness,
        input.emotions?.calmness,
        weightE,
      ),
      warmth: this.mix(currentEmotions.warmth, input.emotions?.warmth, weightE),
      happiness: this.mix(
        currentEmotions.happiness,
        input.emotions?.happiness,
        weightE,
      ),
    };

    const personality = [
      this.mix(currentPersonality[0], input.personality?.[0], weightP),
      this.mix(currentPersonality[1], input.personality?.[1], weightP),
      this.mix(currentPersonality[2], input.personality?.[2], weightP),
    ];

    return {
      emotions,
      personality,
      latestEmotion: input.latestEmotion || this.latestEmotion,
    };
  }

  private mix(current: number, next: number | undefined, weight: number) {
    return Math.round(current * (1 - weight) + (next ?? current) * weight);
  }
}

import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';

export interface UpdateUserFrequencyInput {
  userId: string;
  mood: string;
  vibe: string;
  signal: string;
  frequencyHertz?: string;
}

export class UpdateUserFrequencyUseCase {
  constructor(private readonly userRepository: UserRepository) {}

  async execute(input: UpdateUserFrequencyInput) {
    const user = await this.userRepository.findById(input.userId);
    if (!user) {
      throw new Error('User not found');
    }

    let dominantEmotion = 'Sâu lắng';
    let moodIcon = '🌙';
    let defaultHertz = '528 Hz';
    let emotions = {
      stress: 3,
      loneliness: 6,
      sadness: 5,
      calmness: 6,
      warmth: 5,
      happiness: 4,
    };

    const lowerMood = input.mood.toLowerCase();
    if (
      lowerMood.includes('chùng') ||
      lowerMood.includes('cô đơn') ||
      lowerMood.includes('tĩnh')
    ) {
      dominantEmotion = 'Cô đơn';
      moodIcon = '🌧️';
      defaultHertz = '528 Hz';
      emotions = {
        stress: 4,
        loneliness: 9,
        sadness: 7,
        calmness: 4,
        warmth: 2,
        happiness: 2,
      };
    } else if (
      lowerMood.includes('chill') ||
      lowerMood.includes('bình yên') ||
      lowerMood.includes('lắng đọng')
    ) {
      dominantEmotion = 'Bình yên';
      moodIcon = '☕';
      defaultHertz = '432 Hz';
      emotions = {
        stress: 2,
        loneliness: 3,
        sadness: 2,
        calmness: 9,
        warmth: 7,
        happiness: 6,
      };
    } else if (
      lowerMood.includes('hứng') ||
      lowerMood.includes('năng lượng') ||
      lowerMood.includes('high')
    ) {
      dominantEmotion = 'Phấn khích';
      moodIcon = '✨';
      defaultHertz = '741 Hz';
      emotions = {
        stress: 1,
        loneliness: 1,
        sadness: 1,
        calmness: 5,
        warmth: 8,
        happiness: 9,
      };
    }

    // Xử lý Tags dựa trên Signal & Vibe
    const tagsSet = new Set<string>();
    const lowerSignal = input.signal.toLowerCase();
    const lowerVibe = input.vibe.toLowerCase();

    if (lowerSignal.includes('indie') || lowerSignal.includes('nhạc') || lowerSignal.includes('lofi')) {
      tagsSet.add('#NhạcIndie');
      tagsSet.add('#ĐêmMuộn');
    }
    if (lowerSignal.includes('cà phê') || lowerSignal.includes('chill')) {
      tagsSet.add('#CàPhê');
      tagsSet.add('#ChillVibe');
    }
    if (lowerSignal.includes('mưa') || lowerSignal.includes('dạo')) {
      tagsSet.add('#DạoPhố');
      tagsSet.add('#NgắmMưa');
    }
    if (lowerSignal.includes('sách') || lowerSignal.includes('chiêm')) {
      tagsSet.add('#ĐọcSách');
      tagsSet.add('#DeepTalk');
    }

    if (lowerVibe.includes('lắng nghe')) {
      tagsSet.add('#LắngNghe');
    }
    if (lowerVibe.includes('deep')) {
      tagsSet.add('#DeepTalk');
    }
    if (lowerVibe.includes('hài') || lowerVibe.includes('vui')) {
      tagsSet.add('#HàiHước');
    }

    if (tagsSet.size === 0) {
      tagsSet.add('#ĐồngĐiệu');
      tagsSet.add('#TâmSự');
    }

    const updatedUser = await this.userRepository.updateFrequency(input.userId, {
      latestEmotion: dominantEmotion,
      moodIcon,
      frequencyHertz: input.frequencyHertz || defaultHertz,
      desiredVibe: input.vibe,
      tags: Array.from(tagsSet),
      emotions,
    });

    return {
      success: true,
      latestEmotion: dominantEmotion,
      moodIcon,
      frequencyHertz: input.frequencyHertz || defaultHertz,
      tags: Array.from(tagsSet),
      emotions,
      user: updatedUser,
    };
  }
}

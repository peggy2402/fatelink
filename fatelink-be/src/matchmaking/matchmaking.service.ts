import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
// LƯU Ý: Hãy đảm bảo bạn có Schema User. Tạm thời dùng 'User' dạng string để mapping.
// import { UserDocument } from '../users/schemas/user.schema';

@Injectable()
export class MatchmakingService {
  private readonly logger = new Logger(MatchmakingService.name);

  // Inject Model User (Sử dụng tên Model bạn đã định nghĩa trong DB, thường là 'User')
  constructor(@InjectModel('User') private readonly userModel: Model<any>) {}

  /**
   * Hàm 1: Tính khoảng cách Euclidean (Độ lệch chuẩn) - Tương đồng tính cách
   */
  private calculateEuclideanDistance(vecA: number[], vecB: number[]): number {
    if (!vecA || !vecB || vecA.length !== vecB.length) return 0;
    let sum = 0;
    for (let i = 0; i < vecA.length; i++) {
      sum += Math.pow(vecA[i] - vecB[i], 2);
    }
    return Math.sqrt(sum);
  }

  /**
   * Hàm 2: Logic Bù trừ cảm xúc (Complementary Matrix)
   */
  private calculateComplementaryScore(userAEmotions: any, userBEmotions: any): number {
    if (!userAEmotions || !userBEmotions) return 50; // Base score nếu thiếu dữ liệu
    let score = 0;
    
    // Bù trừ 1: Áp lực (Stress) cần Bình tĩnh (Calmness)
    score += (userAEmotions.stress || 0) * (userBEmotions.calmness || 0) * 0.5;
    score += (userBEmotions.stress || 0) * (userAEmotions.calmness || 0) * 0.5;

    // Bù trừ 2: Cô đơn (Loneliness) cần Ấm áp (Warmth)
    score += (userAEmotions.loneliness || 0) * (userBEmotions.warmth || 0) * 0.5;
    score += (userBEmotions.loneliness || 0) * (userAEmotions.warmth || 0) * 0.5;

    // Bù trừ 3: Buồn bã (Sadness) cần Vui vẻ (Happiness)
    score += (userAEmotions.sadness || 0) * (userBEmotions.happiness || 0) * 0.5;
    score += (userBEmotions.sadness || 0) * (userAEmotions.happiness || 0) * 0.5;

    return Math.min(100, score);
  }

  /**
   * API này sẽ được gọi ở HomeScreen để lấy danh sách người dùng ẩn danh phù hợp
   */
  async getRecommendations(userId: string) {
    // 1. Lấy dữ liệu THỰC TẾ của người dùng hiện tại từ MongoDB
    let currentUser;
    try {
      currentUser = await this.userModel.findById(userId).exec();
    } catch (error: any) {
      this.logger.error(`Invalid userId format or DB error: ${error.message}`);
    }

    if (!currentUser) {
      this.logger.warn(`User ${userId} not found, returning fallback mock data.`);
      return this._getMockRecommendations();
    }

    // 2. Lấy danh sách TẤT CẢ user khác trong hệ thống
    const potentialMatches = await this.userModel.find({ _id: { $ne: userId } }).exec();

    // 3. Thực hiện tính toán điểm số (Matchmaking Logic)
    const recommendations = potentialMatches.map(candidate => {
      // Mặc định vector tính cách [5,5,5] nếu user chưa đủ data
      const distance = this.calculateEuclideanDistance(
        currentUser.personality || [5, 5, 5], 
        candidate.personality || [5, 5, 5]
      );
      const similarityScore = Math.max(0, 100 - (distance / 17.32) * 100);

      const compScore = this.calculateComplementaryScore(currentUser.emotions, candidate.emotions);

      // Điểm tổng hợp: 60% Bù trừ cảm xúc, 40% Tính cách
      const finalScore = Math.round((compScore * 0.6) + (similarityScore * 0.4));

      return {
        id: candidate._id.toString(),
        displayName: candidate.displayName || candidate.name || 'Người Dấu Tên',
        dominantEmotion: candidate.latestEmotion || 'Bí ẩn',
        bio: candidate.bio || 'Chưa có tiểu sử',
        matchingScore: finalScore,
      };
    });

    // 4. Sắp xếp giảm dần theo điểm số để ưu tiên người hợp nhất lên đầu
    recommendations.sort((a, b) => b.matchingScore - a.matchingScore);

    return recommendations;
  }

  // Dữ liệu dự phòng trong trường hợp bạn chưa đẩy dữ liệu vào DB
  private _getMockRecommendations() {
    return [
      { id: 'mock-1', displayName: 'Trái tim Ấm áp', dominantEmotion: 'Bình yên', bio: 'Luôn ở đây lắng nghe bạn.', matchingScore: 92 },
      { id: 'mock-2', displayName: 'Năng lượng Tích cực', dominantEmotion: 'Vui vẻ', bio: 'Cuộc sống là những chuyến đi!', matchingScore: 78 }
    ];
  }
}

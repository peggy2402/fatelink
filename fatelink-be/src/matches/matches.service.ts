// matches.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';

@Injectable()
export class MatchesService {
  constructor(
    @InjectModel('Match') private matchModel: Model<any>, // Thay 'Match' bằng model của bạn
    // @InjectModel('User') private userModel: Model<any>, // Cập nhật danh sách match của User nếu cần
  ) {}

  async unmatchUsers(userId: string, partnerId: string): Promise<void> {
    // Tìm và xoá mối quan hệ ghép đôi giữa 2 người
    const result = await this.matchModel.deleteOne({
      $or: [
        { user1: userId, user2: partnerId },
        { user1: partnerId, user2: userId }
      ]
    });

    if (result.deletedCount === 0) {
      throw new NotFoundException('Không tìm thấy dữ liệu ghép đôi này.');
    }

    // (Tuỳ chọn) Nếu bạn lưu array `matchedIds` trong User document, hãy  nó ra:
    // await this.userModel.updateMany(
    //   { _id: { : [userId, partnerId] } },
    //   { : { matchedIds: { : [userId, partnerId] } } }
    // );
  }
}

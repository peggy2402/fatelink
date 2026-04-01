import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { MatchmakingController } from './matchmaking.controller';
import { MatchmakingService } from './matchmaking.service';
import { UserSchema } from 'src/users/schemas/user.schema';

@Module({
  imports: [
    // Khai báo Model để MatchmakingService có thể sử dụng (Mở comment dòng dưới khi có Schema)
    MongooseModule.forFeature([{ name: 'User', schema: UserSchema }])
  ],
  controllers: [MatchmakingController],
  providers: [MatchmakingService]
})
export class MatchmakingModule {}

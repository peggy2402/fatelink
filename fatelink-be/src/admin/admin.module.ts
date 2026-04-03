import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { JwtModule } from '@nestjs/jwt';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { SystemConfig, SystemConfigSchema } from './schemas/system-config.schema';
import { User, UserSchema } from '../users/schemas/user.schema';
import { AiModule } from '../ai/ai.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: SystemConfig.name, schema: SystemConfigSchema },
      { name: User.name, schema: UserSchema } 
    ]),
    JwtModule.register({}), // Cấp phép sử dụng JwtService
    AiModule, // Nhúng AiModule để sử dụng hàm test trạng thái AI
  ],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule {}
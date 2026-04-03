import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { User, UserSchema } from './schemas/user.schema';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { JwtModule } from '@nestjs/jwt';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: User.name, schema: UserSchema }]),
    JwtModule.register({}) // cấp phép sử dụng JwtService cho UsersModule
  ],
  providers: [UsersService],
  exports: [UsersService], // This line is crucial
  controllers: [UsersController], // Nếu có controller nào liên quan đến users thì thêm vào đây
})
export class UsersModule {}
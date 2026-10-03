import { USER_REPOSITORY } from '@shared/kernel/injection-tokens';
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { User, UserSchema } from './models/user.model';
import {
  Notification,
  NotificationSchema,
} from './models/notification.model';
import { MongooseUserRepository } from './repositories/mongoose-user.repository';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: User.name, schema: UserSchema },
      { name: Notification.name, schema: NotificationSchema },
    ]),
  ],
  providers: [
    {
      provide: USER_REPOSITORY,
      useClass: MongooseUserRepository,
    },
  ],
  exports: [USER_REPOSITORY],
})
export class UsersPersistenceModule {}

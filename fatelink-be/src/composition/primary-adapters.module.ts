import { Module } from '@nestjs/common';
import { APP_FILTER } from '@nestjs/core';
import { AdminContextModule } from '@contexts/admin/composition/admin-context.module';
import { AuthContextModule } from '@contexts/auth/composition/auth-context.module';
import { ChatContextModule } from '@contexts/chat/composition/chat-context.module';
import { MatchingContextModule } from '@contexts/matching/composition/matching-context.module';
import { SupportContextModule } from '@contexts/support/composition/support-context.module';
import { UsersContextModule } from '@contexts/users/composition/users-context.module';
import { ApplicationErrorFilter } from '@shared/presentation/filters/application-error.filter';

@Module({
  imports: [
    AuthContextModule,
    UsersContextModule,
    SupportContextModule,
    ChatContextModule,
    MatchingContextModule,
    AdminContextModule,
  ],
  providers: [
    {
      provide: APP_FILTER,
      useClass: ApplicationErrorFilter,
    },
  ],
})
export class PrimaryAdaptersModule {}

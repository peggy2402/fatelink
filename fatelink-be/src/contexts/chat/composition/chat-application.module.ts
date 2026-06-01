import { chatUseCaseProviders, chatUseCases } from './chat.providers';
import { AdminPersistenceModule } from '@contexts/admin/infrastructure/admin-persistence.module';
import { ChatPersistenceModule } from '@contexts/chat/infrastructure/chat-persistence.module';
import { Module } from '@nestjs/common';
import { SharedAiProvidersModule } from '@shared/infrastructure/ai-providers.module';
import { UsersApplicationModule } from '@contexts/users/composition/users-application.module';

@Module({
  imports: [
    ChatPersistenceModule,
    AdminPersistenceModule,
    SharedAiProvidersModule,
    UsersApplicationModule,
  ],
  providers: chatUseCaseProviders,
  exports: chatUseCases,
})
export class ChatApplicationModule {}

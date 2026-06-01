import { CHAT_MESSAGE_REPOSITORY } from '@shared/kernel/injection-tokens';
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Message, MessageSchema } from './models/message.model';
import { MongooseChatMessageRepository } from './repositories/mongoose-chat-message.repository';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Message.name, schema: MessageSchema }]),
  ],
  providers: [
    {
      provide: CHAT_MESSAGE_REPOSITORY,
      useClass: MongooseChatMessageRepository,
    },
  ],
  exports: [CHAT_MESSAGE_REPOSITORY],
})
export class ChatPersistenceModule {}

import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { MessageService } from './message.service';
import { MessageController } from './message.controller';
import { Message, MessageSchema } from './schemas/message.schema';

@Module({
  imports: [MongooseModule.forFeature([{ name: Message.name, schema: MessageSchema }])],
  controllers: [MessageController],
  providers: [MessageService],
  exports: [MessageService], // Export ra để AiModule (ChatGateway) có thể gọi được
})
export class MessageModule {}
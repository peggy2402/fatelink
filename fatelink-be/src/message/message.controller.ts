import { Controller, Get, Param, Query } from '@nestjs/common';
import { MessageService } from './message.service';

@Controller('messages')
export class MessageController {
  constructor(private readonly messageService: MessageService) {}

  @Get(':userId')
  async getChatHistory(
    @Param('userId') userId: string,
    @Query('limit') limit: number = 30,
  ) {
    return this.messageService.getHistoryForUser(userId, limit);
  }
}
import { Controller, Get, Inject, Param, Query } from '@nestjs/common';
import type { GetAiChatHistoryUseCase } from '@contexts/chat/application/usecases/get-ai-chat-history.usecase';
import { CHAT_APPLICATION_TOKENS } from '@contexts/chat/composition/chat.tokens';

@Controller('messages')
export class ChatHistoryController {
  constructor(
    @Inject(CHAT_APPLICATION_TOKENS.getHistory)
    private readonly getAiChatHistoryUseCase: GetAiChatHistoryUseCase,
  ) {}

  @Get(':userId')
  async getChatHistory(
    @Param('userId') userId: string,
    @Query('limit') limit: number = 30,
  ) {
    return this.getAiChatHistoryUseCase.execute({ userId, limit });
  }
}

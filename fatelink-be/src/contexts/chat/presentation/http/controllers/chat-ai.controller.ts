import { Controller, Inject, Post, Body } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import type { SendAiMessageUseCase } from '@contexts/chat/application/usecases/send-ai-message.usecase';
import { CHAT_APPLICATION_TOKENS } from '@contexts/chat/composition/chat.tokens';
import { ApiSendAiMessage } from '@contexts/chat/presentation/http/docs/chat.swagger';
import { SendAiMessageDto } from '../dtos/chat-ai.request.dto';

@ApiTags('AI Chat')
@Controller('chat')
export class ChatAiController {
  constructor(
    @Inject(CHAT_APPLICATION_TOKENS.sendAiMessage)
    private readonly sendAiMessageUseCase: SendAiMessageUseCase,
  ) {}

  @Post('message')
  @ApiSendAiMessage()
  async handleIncomingMessage(@Body() dto: SendAiMessageDto) {
    const reply = await this.sendAiMessageUseCase.execute({
      message: dto.message,
      history: dto.history ?? [],
    });

    return {
      success: true,
      reply,
    };
  }
}

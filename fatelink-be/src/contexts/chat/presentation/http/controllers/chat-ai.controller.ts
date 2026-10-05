import { Controller, Inject, Post, Body } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import type { SendAiMessageUseCase } from '@contexts/chat/application/usecases/send-ai-message.usecase';
import type { SuggestRepliesUseCase } from '@contexts/chat/application/usecases/suggest-replies.usecase';
import { CHAT_APPLICATION_TOKENS } from '@contexts/chat/composition/chat.tokens';
import { ApiSendAiMessage } from '@contexts/chat/presentation/http/docs/chat.swagger';
import { SendAiMessageDto, SuggestReplyDto } from '../dtos/chat-ai.request.dto';

@ApiTags('AI Chat')
@Controller('chat')
export class ChatAiController {
  constructor(
    @Inject(CHAT_APPLICATION_TOKENS.sendAiMessage)
    private readonly sendAiMessageUseCase: SendAiMessageUseCase,
    @Inject(CHAT_APPLICATION_TOKENS.suggestReplies)
    private readonly suggestRepliesUseCase: SuggestRepliesUseCase,
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

  @Post('suggest-replies')
  @ApiOperation({
    summary: 'Gợi ý các câu trả lời thông minh dựa trên tin nhắn đối phương',
  })
  @ApiResponse({
    status: 200,
    description: 'Danh sách các câu gợi ý trả lời bằng AI',
  })
  async suggestReplies(@Body() dto: SuggestReplyDto) {
    const suggestions = await this.suggestRepliesUseCase.execute({
      partnerName: dto.partnerName,
      lastPartnerMessage: dto.lastPartnerMessage,
      recentContext: dto.recentContext,
    });

    return {
      success: true,
      suggestions,
    };
  }
}

import {
  Controller,
  Get,
  Post,
  Body,
  Inject,
  Param,
  Query,
  UseGuards,
  Req,
  UnauthorizedException,
} from '@nestjs/common';
import type { Request } from 'express';
import type { GetAiChatHistoryUseCase } from '@contexts/chat/application/usecases/get-ai-chat-history.usecase';
import type { GetDirectChatHistoryUseCase } from '@contexts/chat/application/usecases/get-direct-chat-history.usecase';
import type { GetRecentConversationsUseCase } from '@contexts/chat/application/usecases/get-recent-conversations.usecase';
import type { CreateDirectChatMessageUseCase } from '@contexts/chat/application/usecases/create-direct-chat-message.usecase';
import { CHAT_APPLICATION_TOKENS } from '@contexts/chat/composition/chat.tokens';
import { JwtAuthGuard } from '@contexts/auth/presentation/http/guards/jwt-auth.guard';
import { ChatGateway } from '@contexts/chat/presentation/websocket/gateways/chat.gateway';
import type { AuthenticatedUser } from '@shared/contracts/authenticated-user';

import { SkipThrottle } from '@nestjs/throttler';

type GuardRequest = Request & { user?: AuthenticatedUser };

@SkipThrottle()
@Controller('messages')
export class ChatHistoryController {
  constructor(
    @Inject(CHAT_APPLICATION_TOKENS.getHistory)
    private readonly getAiChatHistoryUseCase: GetAiChatHistoryUseCase,
    @Inject(CHAT_APPLICATION_TOKENS.getDirectHistory)
    private readonly getDirectChatHistoryUseCase: GetDirectChatHistoryUseCase,
    @Inject(CHAT_APPLICATION_TOKENS.getRecentConversations)
    private readonly getRecentConversationsUseCase: GetRecentConversationsUseCase,
    @Inject(CHAT_APPLICATION_TOKENS.createDirectMessage)
    private readonly createDirectChatMessageUseCase: CreateDirectChatMessageUseCase,
    private readonly chatGateway: ChatGateway,
  ) {}

  @Get('conversations')
  @UseGuards(JwtAuthGuard)
  async getRecentConversations(@Req() req: GuardRequest) {
    const userId = req.user?.sub;
    if (!userId) {
      throw new UnauthorizedException('User không xác định');
    }

    return this.getRecentConversationsUseCase.execute({ userId });
  }

  @Get(':userId')
  async getChatHistory(
    @Param('userId') userId: string,
    @Query('limit') limit: number = 30,
  ) {
    return this.getAiChatHistoryUseCase.execute({ userId, limit });
  }

  @Get('direct/:partnerId')
  @UseGuards(JwtAuthGuard)
  async getDirectHistory(
    @Req() req: GuardRequest,
    @Param('partnerId') partnerId: string,
    @Query('limit') limit: number = 50,
    @Query('after') after?: string,
  ) {
    const userId = req.user?.sub;
    if (!userId) {
      throw new UnauthorizedException('User không xác định');
    }

    return this.getDirectChatHistoryUseCase.execute({
      userId,
      partnerId,
      limit: Number(limit) || 50,
      after,
    });
  }

  @Post('direct')
  @UseGuards(JwtAuthGuard)
  async sendDirectMessage(
    @Req() req: GuardRequest,
    @Body()
    body: {
      partnerId: string;
      text: string;
      messageType?: string;
      mediaUrl?: string;
      durationMs?: number;
      waveform?: number[];
      imageUrls?: string[];
      clientMessageId?: string;
    },
  ) {
    const senderId = req.user?.sub;
    if (!senderId) {
      throw new UnauthorizedException('User không xác định');
    }

    const {
      partnerId,
      text,
      messageType,
      mediaUrl,
      durationMs,
      waveform,
      imageUrls,
      clientMessageId,
    } = body;
    if (!partnerId || !text || text.trim().length === 0) {
      throw new UnauthorizedException('partnerId và text là bắt buộc');
    }

    const message = await this.createDirectChatMessageUseCase.execute({
      senderId,
      partnerId,
      text: text.trim(),
      messageType,
      mediaUrl,
      durationMs,
      waveform,
      imageUrls,
      clientMessageId,
    });

    // Phát tin nhắn realtime qua Socket.IO tới đối phương nếu đang online
    this.chatGateway.sendDirectMessageToUser(senderId, partnerId, text.trim(), {
      id: message.id,
      messageType: message.messageType,
      mediaUrl: message.mediaUrl,
      durationMs: message.durationMs,
      waveform: message.waveform,
      imageUrls: message.imageUrls,
      clientMessageId: message.clientMessageId,
      timestamp: (message.createdAt ?? new Date()).toISOString(),
    });

    return {
      success: true,
      message,
    };
  }
}


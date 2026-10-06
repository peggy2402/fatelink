import { Controller, Get, Req, UseGuards } from '@nestjs/common';
import type { Request } from 'express';
import { JwtAuthGuard } from '@contexts/auth/presentation/http/guards/jwt-auth.guard';
import { ChatGateway } from '@contexts/chat/presentation/websocket/gateways/chat.gateway';
import type { AuthenticatedUser } from '@shared/contracts/authenticated-user';

type GuardRequest = Request & { user?: AuthenticatedUser };

@Controller('calls')
@UseGuards(JwtAuthGuard)
export class CallsController {
  constructor(private readonly chatGateway: ChatGateway) {}

  /**
   * Cung cấp cấu hình ICE Servers (STUN + TURN) động cho WebRTC
   * Đọc cấu hình TURN bí mật từ biến môi trường (fly secrets), không hardcode secret.
   */
  @Get('ice-servers')
  getIceServers() {
    const iceServers: Array<{ urls: string | string[]; username?: string; credential?: string }> = [
      {
        urls: [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
          'stun:stun3.l.google.com:19302',
          'stun:stun4.l.google.com:19302',
        ],
      },
    ];

    // Cấu hình TURN nếu được cấp qua Fly Secrets (Coturn hoặc Metered / Cloudflare)
    const turnUrl = process.env.COTURN_URL || process.env.TURN_URL;
    const turnUsername = process.env.COTURN_USERNAME || process.env.TURN_USERNAME;
    const turnCredential = process.env.COTURN_CREDENTIAL || process.env.TURN_CREDENTIAL;

    if (turnUrl && turnUsername && turnCredential) {
      iceServers.push({
        urls: turnUrl.split(','),
        username: turnUsername,
        credential: turnCredential,
      });
    }

    return {
      success: true,
      iceServers,
    };
  }

  /**
   * Lấy cuộc gọi đang đổ chuông nhắm tới user khi app vừa mở hoặc kết nối lại
   */
  @Get('pending')
  getPendingCall(@Req() req: GuardRequest) {
    const userId = req.user?.sub;
    if (!userId) {
      return { success: false, pendingCall: null };
    }

    const pendingCall = this.chatGateway.getPendingCallForUser(userId);
    if (!pendingCall) {
      return { success: true, pendingCall: null };
    }

    return {
      success: true,
      pendingCall: {
        callId: pendingCall.callId,
        callerId: pendingCall.callerId,
        callerName: pendingCall.callerName,
        callerAvatar: pendingCall.callerAvatar,
        sdp: pendingCall.offerSdp,
        createdAt: pendingCall.createdAt.toISOString(),
      },
    };
  }
}

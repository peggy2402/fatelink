import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Inject, Logger } from '@nestjs/common';
import { Server, Socket } from 'socket.io';
import { AUTH_APPLICATION_TOKENS } from '@contexts/auth/composition/auth.tokens';
import { CHAT_APPLICATION_TOKENS } from '@contexts/chat/composition/chat.tokens';
import { ChatPresenceService } from '@contexts/chat/presentation/websocket/services/chat-presence.service';
import type { CreateDirectChatMessageUseCase } from '@contexts/chat/application/usecases/create-direct-chat-message.usecase';
import type { GetDirectChatHistoryUseCase } from '@contexts/chat/application/usecases/get-direct-chat-history.usecase';
import type { HandleRealtimeChatMessageUseCase } from '@contexts/chat/application/usecases/handle-realtime-chat-message.usecase';
import type { ValidateUserTokenUseCase } from '@contexts/auth/application/usecases/validate-user-token.usecase';
import { USER_REPOSITORY } from '@shared/kernel/injection-tokens';
import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';
import { FirebaseNotificationService } from '@shared/infrastructure/notifications/firebase-notification.service';

const websocketCorsOrigins = (
  process.env.WEBSOCKET_CORS_ORIGINS ||
  'http://localhost:3000,http://10.0.2.2:3000,https://fatelink-be.fly.dev'
)
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

type ClientToServerEvents = {
  sendMessage: (payload: { text: string }) => void;
  sendDirectMessage: (payload: { partnerId: string; text: string }) => void;
  loadDirectHistory: (payload: { partnerId: string; limit?: number }) => void;
  checkUserStatus: (payload: { targetUserId: string }) => void;
  checkUsersStatus: (payload: { targetUserIds: string[] }) => void;
  typing: (payload: { partnerId: string; isTyping: boolean }) => void;
};

type ServerToClientEvents = {
  authError: (payload: { message: string }) => void;
  userStatusChanged: (payload: { userId: string; isOnline: boolean }) => void;
  receiveMessage: (payload: {
    text: string;
    isSentByMe: boolean;
    timestamp: string;
  }) => void;
  matchReady: (payload: { message: string }) => void;
  errorMessage: (payload: { message: string }) => void;
  receiveDirectMessage: (payload: {
    senderId: string;
    text: string;
    timestamp: string;
  }) => void;
  directHistoryResult: (payload: {
    partnerId: string;
    messages: Array<{
      text: string;
      isSentByMe: boolean;
      timestamp: string;
    }>;
  }) => void;
  userStatusResult: (payload: { userId: string; isOnline: boolean }) => void;
  usersStatusResult: (payload: Record<string, boolean>) => void;
  receiveTyping: (payload: { senderId: string; isTyping: boolean }) => void;
};

type InterServerEvents = Record<string, never>;
type ChatSocketData = { userId?: string };
type ChatSocket = Socket<
  ClientToServerEvents,
  ServerToClientEvents,
  InterServerEvents,
  ChatSocketData
>;

type ChatServer = Server<
  ClientToServerEvents,
  ServerToClientEvents,
  InterServerEvents,
  ChatSocketData
>;

@WebSocketGateway({
  cors: {
    origin: websocketCorsOrigins,
  },
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  private readonly logger = new Logger(ChatGateway.name);

  @WebSocketServer()
  server!: ChatServer; // Thêm '!' để khắc phục lỗi "has no initializer"

  constructor(
    @Inject(CHAT_APPLICATION_TOKENS.handleRealtimeMessage)
    private readonly handleRealtimeChatMessageUseCase: HandleRealtimeChatMessageUseCase,
    @Inject(AUTH_APPLICATION_TOKENS.validateUserToken)
    private readonly validateUserTokenUseCase: ValidateUserTokenUseCase,
    @Inject(CHAT_APPLICATION_TOKENS.createDirectMessage)
    private readonly createDirectChatMessageUseCase: CreateDirectChatMessageUseCase,
    @Inject(CHAT_APPLICATION_TOKENS.getDirectHistory)
    private readonly getDirectChatHistoryUseCase: GetDirectChatHistoryUseCase,
    private readonly chatPresenceService: ChatPresenceService,
    @Inject(USER_REPOSITORY)
    private readonly userRepository: UserRepository,
    private readonly firebaseNotificationService: FirebaseNotificationService,
  ) {}

  async handleConnection(client: ChatSocket) {
    try {
      // 1. Lấy token linh hoạt từ handshake auth, headers, hoặc query
      const auth = client.handshake.auth as { token?: string } | undefined;
      let token = auth?.token;

      if (!token && client.handshake.headers?.authorization) {
        token = client.handshake.headers.authorization;
      }

      if (!token && client.handshake.query?.token) {
        token = String(client.handshake.query.token);
      }

      if (!token) {
        throw new Error('Missing websocket auth token');
      }

      // 2. Chuẩn hóa token: xóa tiền tố 'Bearer ' và khoảng trắng
      if (token.startsWith('Bearer ')) {
        token = token.slice(7).trim();
      } else {
        token = token.trim();
      }

      const decoded = await this.validateUserTokenUseCase.execute({ token });
      const userId = decoded.sub;

      // Gắn userId vào client data để dùng cho các luồng nhắn tin sau này
      client.data.userId = userId;
      this.logger.log(`Client connected: ${client.id} (User: ${userId})`);

      this.chatPresenceService.markOnline(userId, client.id);

      // Broadcast cho toàn bộ client biết user này vừa online
      this.server.emit('userStatusChanged', {
        userId,
        isOnline: true,
      });
    } catch (err: unknown) {
      const reason = err instanceof Error ? err.message : String(err);
      this.logger.warn(`Rejected websocket connection: ${client.id}. Reason: ${reason}`);
      client.emit('authError', { message: reason });
      client.disconnect(); // Ngắt kết nối ngay nếu không xác thực được
    }
  }

  handleDisconnect(client: ChatSocket) {
    if (client.data.userId) {
      const isFullyOffline = this.chatPresenceService.markOffline(
        client.data.userId,
        client.id,
      );

      if (isFullyOffline) {
        // TỐI ƯU: Broadcast cho toàn bộ client biết user này vừa offline
        this.server.emit('userStatusChanged', {
          userId: client.data.userId,
          isOnline: false,
        });
      }
    }
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('sendMessage')
  async handleMessage(
    @ConnectedSocket() client: ChatSocket,
    @MessageBody() payload: { text: string }, // Client chỉ cần gửi text
  ) {
    this.logger.log(`Received websocket message from ${client.id}`);

    try {
      const userId = client.data.userId;
      if (!userId) {
        throw new Error('User không xác định');
      }
      const result = await this.handleRealtimeChatMessageUseCase.execute({
        userId,
        text: payload.text,
      });

      // 5. Phát sự kiện 'receiveMessage' trả lời lại đúng client đó
      client.emit('receiveMessage', {
        text: result.reply,
        isSentByMe: false,
        timestamp: new Date().toISOString(),
      });

      // 6. Nếu AI báo đã sẵn sàng ghép cặp (Kích hoạt Phase 2)
      if (result.isReadyToMatch) {
        client.emit('matchReady', {
          message: 'Faye đã hiểu bạn! Đang tìm kiếm định mệnh...',
        });
      }
    } catch (error: unknown) {
      // Khắc phục lỗi 'error' is of type 'unknown'
      this.logger.error(
        'Failed to handle websocket message',
        error instanceof Error ? error.stack || error.message : String(error),
      );
      client.emit('errorMessage', {
        message: 'Faye đang bận chút việc, bạn thử lại sau nhé!',
      });
    }
  }

  // --- GIAO TIẾP 1-1 (GIỮA 2 USER THẬT) ---
  @SubscribeMessage('sendDirectMessage')
  async handleDirectMessage(
    @ConnectedSocket() client: ChatSocket,
    @MessageBody() payload: { partnerId: string; text: string },
  ) {
    try {
      const senderId = client.data.userId;
      const { partnerId, text } = payload;

      if (!senderId) {
        client.emit('errorMessage', { message: 'User không xác định' });
        return;
      }

      await this.createDirectChatMessageUseCase.execute({
        senderId,
        partnerId,
        text,
      });

      const targetSocketIds = this.chatPresenceService.getSocketIds(partnerId);

      if (targetSocketIds.length > 0) {
        // Đối phương đang mở app -> Bắn sự kiện realtime
        targetSocketIds.forEach((targetSocketId) => {
          this.server.to(targetSocketId).emit('receiveDirectMessage', {
            senderId,
            text,
            timestamp: new Date().toISOString(),
          });
        });
      } else {
        this.logger.log(`Direct message target offline: ${partnerId}`);
      }

      // Kích hoạt Push Notification (Heads-Up trên màn hình chính/khóa & badge icon)
      void this.notifyDirectMessage(senderId, partnerId, text);
    } catch (error: unknown) {
      this.logger.error(
        'Failed to handle direct websocket message',
        error instanceof Error ? error.stack || error.message : String(error),
      );
      client.emit('errorMessage', {
        message: 'Khong the gui tin nhan luc nay, ban thu lai sau nhe!',
      });
    }
  }

  /**
   * Phát tin nhắn trực tiếp qua socket khi tin nhắn được gửi từ HTTP REST Controller
   */
  sendDirectMessageToUser(senderId: string, partnerId: string, text: string) {
    try {
      const targetSocketIds = this.chatPresenceService.getSocketIds(partnerId);
      if (targetSocketIds.length > 0 && this.server) {
        targetSocketIds.forEach((targetSocketId) => {
          this.server.to(targetSocketId).emit('receiveDirectMessage', {
            senderId,
            text,
            timestamp: new Date().toISOString(),
          });
        });
      }

      // Kích hoạt Push Notification cho HTTP
      void this.notifyDirectMessage(senderId, partnerId, text);
    } catch (error) {
      this.logger.error('Failed to broadcast direct message from HTTP', error);
    }
  }

  /**
   * Bắn thông báo đẩy FCM tới thiết bị Android của người nhận
   */
  private async notifyDirectMessage(
    senderId: string,
    partnerId: string,
    text: string,
  ): Promise<void> {
    try {
      const [partner, sender] = await Promise.all([
        this.userRepository.findById(partnerId),
        this.userRepository.findById(senderId),
      ]);

      if (partner?.fcmToken) {
        const senderName = sender?.name || 'Bạn mới trên FateLink';
        let displayBody = text;
        if (text.startsWith('🎙️') || text.includes('[voice:')) {
          displayBody = '🎙️ [Tin nhắn thoại]';
        } else if (text.startsWith('[Hình ảnh]')) {
          displayBody = '📷 [Hình ảnh]';
        } else if (text.startsWith('📍 [Vị trí]')) {
          displayBody = '📍 [Vị trí được chia sẻ]';
        }

        await this.firebaseNotificationService.sendPushNotification(
          partner.fcmToken,
          {
            title: senderName,
            body: displayBody,
            data: {
              partnerId: senderId,
              senderName,
              type: 'direct_chat',
            },
            badgeCount: 1,
          },
        );
      }
    } catch (pushErr) {
      this.logger.warn(`Push notification trigger failed: ${pushErr}`);
    }
  }

  // --- TÍNH NĂNG TRẠNG THÁI ONLINE/OFFLINE ---
  @SubscribeMessage('checkUserStatus')
  handleCheckUserStatus(
    @ConnectedSocket() client: ChatSocket,
    @MessageBody() payload: { targetUserId: string },
  ) {
    const isOnline = this.chatPresenceService.isOnline(payload.targetUserId);
    client.emit('userStatusResult', {
      userId: payload.targetUserId,
      isOnline,
    });
  }

  // --- TÍNH NĂNG KIỂM TRA TRẠNG THÁI NHIỀU USER CÙNG LÚC ---
  @SubscribeMessage('checkUsersStatus')
  handleCheckUsersStatus(
    @ConnectedSocket() client: ChatSocket,
    @MessageBody() payload: { targetUserIds: string[] },
  ) {
    client.emit(
      'usersStatusResult',
      this.chatPresenceService.getManyStatuses(
        Array.isArray(payload.targetUserIds) ? payload.targetUserIds : [],
      ),
    );
  }

  // --- TÍNH NĂNG "ĐANG GÕ..." (TYPING) ---
  @SubscribeMessage('typing')
  handleTyping(
    @ConnectedSocket() client: ChatSocket,
    @MessageBody() payload: { partnerId: string; isTyping: boolean },
  ) {
    const senderId = client.data.userId;
    if (!senderId) {
      return;
    }

    const targetSocketIds = this.chatPresenceService.getSocketIds(
      payload.partnerId,
    );
    targetSocketIds.forEach((targetSocketId) => {
      this.server.to(targetSocketId).emit('receiveTyping', {
        senderId,
        isTyping: payload.isTyping,
      });
    });
  }

  // --- TẢI LỊCH SỬ TIN NHẮN 1-1 THẬT GIỮA 2 USER ---
  @SubscribeMessage('loadDirectHistory')
  async handleLoadDirectHistory(
    @ConnectedSocket() client: ChatSocket,
    @MessageBody() payload: { partnerId: string; limit?: number },
  ) {
    const userId = client.data.userId;
    if (!userId) {
      return;
    }

    try {
      const messages = await this.getDirectChatHistoryUseCase.execute({
        userId,
        partnerId: payload.partnerId,
        limit: payload.limit || 50,
      });

      client.emit('directHistoryResult', {
        partnerId: payload.partnerId,
        messages,
      });
    } catch (error: unknown) {
      this.logger.error(
        'Failed to load direct history',
        error instanceof Error ? error.stack || error.message : String(error),
      );
    }
  }
}

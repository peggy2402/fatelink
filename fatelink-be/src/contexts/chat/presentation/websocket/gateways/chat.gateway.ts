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
import type { HandleRealtimeChatMessageUseCase } from '@contexts/chat/application/usecases/handle-realtime-chat-message.usecase';
import type { ValidateUserTokenUseCase } from '@contexts/auth/application/usecases/validate-user-token.usecase';

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
  checkUserStatus: (payload: { targetUserId: string }) => void;
  checkUsersStatus: (payload: { targetUserIds: string[] }) => void;
  typing: (payload: { partnerId: string; isTyping: boolean }) => void;
};

type ServerToClientEvents = {
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
    private readonly chatPresenceService: ChatPresenceService,
  ) {}

  async handleConnection(client: ChatSocket) {
    try {
      // Lấy token từ handshake auth do Flutter gửi lên
      const auth = client.handshake.auth as { token?: string } | undefined;
      const token = auth?.token;
      if (!token) {
        throw new Error('Missing websocket auth token');
      }

      const decoded = await this.validateUserTokenUseCase.execute({ token });
      const userId = decoded.sub;

      // Gắn userId vào client data để dùng cho các luồng nhắn tin sau này
      client.data.userId = userId;
      this.logger.log(`Client connected: ${client.id} (User: ${userId})`);

      this.chatPresenceService.markOnline(userId, client.id);

      // TỐI ƯU: Broadcast cho toàn bộ client biết user này vừa online
      this.server.emit('userStatusChanged', {
        userId,
        isOnline: true,
      });
    } catch {
      this.logger.warn(`Rejected websocket connection: ${client.id}`);
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
        // Đối phương đang tắt app hoặc chạy nền -> Kích hoạt Push Notification
        this.logger.log(`Direct message target offline: ${partnerId}`);
      }
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
}

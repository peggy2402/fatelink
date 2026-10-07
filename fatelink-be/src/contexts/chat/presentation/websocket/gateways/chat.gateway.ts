import { randomUUID } from 'crypto';
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
  sendDirectMessage: (
    payload: {
      partnerId: string;
      text: string;
      messageType?: string;
      mediaUrl?: string;
      durationMs?: number;
      waveform?: number[];
      imageUrls?: string[];
      clientMessageId?: string;
    },
    callback?: (ack: {
      success: boolean;
      id?: string;
      clientMessageId?: string;
      timestamp?: string;
      error?: string;
    }) => void,
  ) => void;
  loadDirectHistory: (payload: { partnerId: string; limit?: number; after?: string }) => void;
  checkUserStatus: (payload: { targetUserId: string }) => void;
  checkUsersStatus: (payload: { targetUserIds: string[] }) => void;
  typing: (payload: { partnerId: string; isTyping: boolean }) => void;
  startVoiceCall: (payload: { partnerId: string; sdp: any }) => void;
  acceptVoiceCall: (payload: { callId: string; callerId: string }) => void;
  rejectVoiceCall: (payload: { callId: string; callerId: string; reason?: string }) => void;
  endVoiceCall: (payload: { callId?: string; partnerId: string; reason?: string }) => void;
  webrtcAnswer: (payload: { callId?: string; partnerId: string; sdp: any }) => void;
  iceCandidate: (payload: { callId?: string; partnerId: string; candidate: any }) => void;
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
    id?: string;
    senderId: string;
    text: string;
    timestamp: string;
    messageType?: string;
    mediaUrl?: string | null;
    durationMs?: number | null;
    waveform?: number[] | null;
    imageUrls?: string[] | null;
    clientMessageId?: string | null;
  }) => void;
  directHistoryResult: (payload: {
    partnerId: string;
    messages: Array<{
      id?: string;
      text: string;
      isSentByMe: boolean;
      timestamp: string;
      messageType?: string;
      mediaUrl?: string | null;
      durationMs?: number | null;
      waveform?: number[] | null;
      imageUrls?: string[] | null;
      clientMessageId?: string | null;
    }>;
  }) => void;
  userStatusResult: (payload: { userId: string; isOnline: boolean }) => void;
  usersStatusResult: (payload: Record<string, boolean>) => void;
  receiveTyping: (payload: { senderId: string; isTyping: boolean }) => void;
  incomingVoiceCall: (payload: {
    callId: string;
    callerId: string;
    callerName: string;
    callerAvatar: string | null;
    sdp: any;
    timestamp: string;
  }) => void;
  voiceCallRinging: (payload: { callId: string; partnerId: string }) => void;
  voiceCallBusy: (payload: { partnerId: string }) => void;
  voiceCallMissed: (payload: { callId: string; partnerId: string }) => void;
  voiceCallAccepted: (payload: { callId: string; partnerId: string }) => void;
  voiceCallRejected: (payload: { callId: string; partnerId: string; reason: string }) => void;
  voiceCallEnded: (payload: { callId?: string; partnerId: string; reason?: string }) => void;
  voiceCallAnsweredElsewhere: (payload: { callId: string }) => void;
  webrtcAnswer: (payload: { callId?: string; senderId: string; sdp: any }) => void;
  iceCandidate: (payload: { callId?: string; senderId: string; candidate: any }) => void;
};

export interface VoiceCallSession {
  callId: string;
  callerId: string;
  calleeId: string;
  callerName: string;
  callerAvatar: string | null;
  offerSdp: any;
  status: 'ringing' | 'connected' | 'ended';
  createdAt: Date;
  timeoutTimer?: NodeJS.Timeout;
}

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

  private readonly activeCalls = new Map<string, VoiceCallSession>();
  private readonly userActiveCallMap = new Map<string, string>(); // userId -> callId

  public cleanupCall(callId: string) {
    const session = this.activeCalls.get(callId);
    if (!session) return;
    if (session.timeoutTimer) {
      clearTimeout(session.timeoutTimer);
      session.timeoutTimer = undefined;
    }
    this.activeCalls.delete(callId);
    if (this.userActiveCallMap.get(session.callerId) === callId) {
      this.userActiveCallMap.delete(session.callerId);
    }
    if (this.userActiveCallMap.get(session.calleeId) === callId) {
      this.userActiveCallMap.delete(session.calleeId);
    }
    this.logger.log(`[Call Cleanup] callId=${callId} cleaned up`);
  }

  public getPendingCallForUser(userId: string): VoiceCallSession | null {
    const callId = this.userActiveCallMap.get(userId);
    if (!callId) return null;
    const session = this.activeCalls.get(callId);
    if (session && session.calleeId === userId && session.status === 'ringing') {
      return session;
    }
    return null;
  }

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

      const machineId = process.env.FLY_MACHINE_ID || process.env.HOSTNAME || 'local';
      // Gắn userId vào client data để dùng cho các luồng nhắn tin sau này
      client.data.userId = userId;
      // Join room định danh user:{userId} cho room-based routing
      client.join(`user:${userId}`);

      this.chatPresenceService.markOnline(userId, client.id);
      const activeCount = this.chatPresenceService.getSocketIds(userId).length;

      this.logger.log(
        `[Socket Connect] machine=${machineId}, socketId=${client.id}, userId=${userId}, activeSockets=${activeCount}`,
      );

      // Broadcast cho toàn bộ client biết user này vừa online
      this.server.emit('userStatusChanged', {
        userId,
        isOnline: true,
      });

      // Nếu đang có cuộc gọi đang ringing nhắm tới user này, re-emit cho socket vừa kết nối
      const pendingCall = this.getPendingCallForUser(userId);
      if (pendingCall) {
        this.logger.log(`[Pending Call Re-emit on Connect] userId=${userId}, callId=${pendingCall.callId}`);
        client.emit('incomingVoiceCall', {
          callId: pendingCall.callId,
          callerId: pendingCall.callerId,
          callerName: pendingCall.callerName,
          callerAvatar: pendingCall.callerAvatar,
          sdp: pendingCall.offerSdp,
          timestamp: pendingCall.createdAt.toISOString(),
        });
      }
    } catch (err: unknown) {
      const reason = err instanceof Error ? err.message : String(err);
      this.logger.warn(`Rejected websocket connection: ${client.id}. Reason: ${reason}`);
      client.emit('authError', { message: reason });
      client.disconnect(); // Ngắt kết nối ngay nếu không xác thực được
    }
  }

  handleDisconnect(client: ChatSocket) {
    const machineId = process.env.FLY_MACHINE_ID || process.env.HOSTNAME || 'local';
    if (client.data.userId) {
      const userId = client.data.userId;
      client.leave(`user:${userId}`);
      const isFullyOffline = this.chatPresenceService.markOffline(
        userId,
        client.id,
      );

      if (isFullyOffline) {
        // TỐI ƯU: Broadcast cho toàn bộ client biết user này vừa offline
        this.server.emit('userStatusChanged', {
          userId,
          isOnline: false,
        });

        // Xử lý cuộc gọi nếu user ngắt kết nối hoàn toàn
        const callId = this.userActiveCallMap.get(userId);
        if (callId) {
          const session = this.activeCalls.get(callId);
          if (session) {
            const partnerId = session.callerId === userId ? session.calleeId : session.callerId;
            this.logger.log(`[Call Cleanup on Disconnect] callId=${callId}, disconnectedUser=${userId}, notifyPartner=${partnerId}`);
            this.server.to(`user:${partnerId}`).emit('voiceCallEnded', {
              callId,
              partnerId: userId,
              reason: 'peer_disconnected',
            });
            this.cleanupCall(callId);
          }
        }
      }

      this.logger.log(
        `[Socket Disconnect] machine=${machineId}, socketId=${client.id}, userId=${userId}, isFullyOffline=${isFullyOffline}`,
      );
    } else {
      this.logger.log(`[Socket Disconnect] machine=${machineId}, socketId=${client.id} (no userId)`);
    }
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
    @MessageBody()
    payload: {
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
    const machineId = process.env.FLY_MACHINE_ID || process.env.HOSTNAME || 'local';
    const senderId = client.data.userId;
    const {
      partnerId,
      text,
      messageType,
      mediaUrl,
      durationMs,
      waveform,
      imageUrls,
      clientMessageId,
    } = payload;

    this.logger.log(
      `[Socket sendDirectMessage:START] machine=${machineId}, senderId=${senderId}, partnerId=${partnerId}, clientMessageId=${clientMessageId}, messageType=${messageType || 'text'}`,
    );

    if (!senderId) {
      client.emit('errorMessage', { message: 'User không xác định' });
      return { success: false, error: 'User không xác định' };
    }

    try {
      const savedMessage = await this.createDirectChatMessageUseCase.execute({
        senderId,
        partnerId,
        text,
        messageType,
        mediaUrl,
        durationMs,
        waveform,
        imageUrls,
        clientMessageId,
      });

      const messageTimestamp = (savedMessage?.createdAt ?? new Date()).toISOString();
      const messageId = savedMessage?.id;
      const targetSocketIds = this.chatPresenceService.getSocketIds(partnerId);

      this.logger.log(
        `[Socket sendDirectMessage:SAVED] machine=${machineId}, senderId=${senderId}, partnerId=${partnerId}, messageId=${messageId}, clientMessageId=${clientMessageId}, dbSaved=true, targetSocketIdsCount=${targetSocketIds.length}`,
      );

      const messagePayload = {
        id: messageId,
        senderId,
        text,
        messageType: savedMessage?.messageType || messageType,
        mediaUrl: savedMessage?.mediaUrl ?? mediaUrl,
        durationMs: savedMessage?.durationMs ?? durationMs,
        waveform: savedMessage?.waveform ?? waveform,
        imageUrls: savedMessage?.imageUrls ?? imageUrls,
        clientMessageId: savedMessage?.clientMessageId ?? clientMessageId,
        timestamp: messageTimestamp,
      };

      // 1. Phát tới room 'user:${partnerId}' (chuẩn đa máy + Redis adapter)
      this.server.to(`user:${partnerId}`).emit('receiveDirectMessage', messagePayload);

      this.logger.log(
        `[Socket sendDirectMessage:EMITTED] machine=${machineId}, partnerId=${partnerId}, targetRoom=user:${partnerId}, socketsNotified=${targetSocketIds.length}`,
      );

      // Kích hoạt Push Notification (Heads-Up trên màn hình chính/khóa & badge icon)
      void this.notifyDirectMessage(senderId, partnerId, text);

      // Trả về ack cho client (NestJS tự động chuyển giá trị return thành ack response)
      return {
        success: true,
        id: messageId,
        clientMessageId: savedMessage?.clientMessageId ?? clientMessageId,
        timestamp: messageTimestamp,
      };
    } catch (error: unknown) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      this.logger.error(
        `[Socket sendDirectMessage:ERROR] machine=${machineId}, senderId=${senderId}, partnerId=${partnerId}, error=${errorMsg}`,
        error instanceof Error ? error.stack : undefined,
      );
      client.emit('errorMessage', {
        message: 'Khong the gui tin nhan luc nay, ban thu lai sau nhe!',
      });
      return {
        success: false,
        error: errorMsg,
        clientMessageId,
      };
    }
  }

  /**
   * Phát tin nhắn trực tiếp qua socket khi tin nhắn được gửi từ HTTP REST Controller
   */
  sendDirectMessageToUser(
    senderId: string,
    partnerId: string,
    text: string,
    options?: {
      id?: string;
      messageType?: string;
      mediaUrl?: string;
      durationMs?: number;
      waveform?: number[];
      imageUrls?: string[];
      clientMessageId?: string;
      timestamp?: string;
    },
  ) {
    try {
      const machineId = process.env.FLY_MACHINE_ID || process.env.HOSTNAME || 'local';
      const targetSocketIds = this.chatPresenceService.getSocketIds(partnerId);
      const messagePayload = {
        id: options?.id,
        senderId,
        text,
        timestamp: options?.timestamp || new Date().toISOString(),
        messageType: options?.messageType,
        mediaUrl: options?.mediaUrl,
        durationMs: options?.durationMs,
        waveform: options?.waveform,
        imageUrls: options?.imageUrls,
        clientMessageId: options?.clientMessageId,
      };

      if (this.server) {
        // Emit tới room (đã bao gồm toàn bộ socket của user)
        this.server.to(`user:${partnerId}`).emit('receiveDirectMessage', messagePayload);
      }

      this.logger.log(
        `[HTTP sendDirectMessage:EMITTED] machine=${machineId}, partnerId=${partnerId}, sockets=${targetSocketIds.length}`,
      );

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
        if (
          text.startsWith('🎙️') ||
          text.includes('[voice:') ||
          text.includes('"type":"voice"') ||
          text.includes('"voice"')
        ) {
          displayBody = '🎙️ Tin nhắn thoại';
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
      } else {
        this.logger.warn(
          `[FCM Notification Skipped] Partner ${partnerId} does not have an fcmToken`,
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

    this.server.to(`user:${payload.partnerId}`).emit('receiveTyping', {
      senderId,
      isTyping: payload.isTyping,
    });
  }

  // --- TẢI LỊCH SỬ TIN NHẮN 1-1 THẬT GIỮA 2 USER ---
  @SubscribeMessage('loadDirectHistory')
  async handleLoadDirectHistory(
    @ConnectedSocket() client: ChatSocket,
    @MessageBody() payload: { partnerId: string; limit?: number; after?: string },
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
        after: payload.after,
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

  // ==========================================
  // --- HỆ THỐNG CUỘC GỌI THOẠI REAL-TIME (VOICE CALL SIGNALING) ---
  // ==========================================

  /**
   * Bắt đầu cuộc gọi thoại: Người gọi kích hoạt cuộc gọi tới bạn bè kèm SDP Offer
   */
  @SubscribeMessage('startVoiceCall')
  async handleStartVoiceCall(
    @ConnectedSocket() client: ChatSocket,
    @MessageBody() payload: { partnerId: string; sdp: any },
  ) {
    const senderId = client.data.userId;
    if (!senderId) return;

    try {
      const { partnerId, sdp } = payload;

      // 1. Kiểm tra đối phương có đang bận trong cuộc gọi khác không
      const partnerActiveCallId = this.userActiveCallMap.get(partnerId);
      if (partnerActiveCallId) {
        const partnerSession = this.activeCalls.get(partnerActiveCallId);
        if (!partnerSession) {
          // Phiên gọi cũ đã dọn nhưng map còn sót -> xóa rác ngay lập tức
          this.userActiveCallMap.delete(partnerId);
        } else {
          this.logger.warn(`User ${partnerId} is already in active call ${partnerActiveCallId}`);
          client.emit('voiceCallBusy', { partnerId });
          return;
        }
      }

      // Nếu người gọi có cuộc gọi cũ còn sót trong map, dọn dẹp trước
      const existingCallId = this.userActiveCallMap.get(senderId);
      if (existingCallId) {
        this.cleanupCall(existingCallId);
      }
      this.userActiveCallMap.delete(senderId);

      const [caller, partner] = await Promise.all([
        this.userRepository.findById(senderId),
        this.userRepository.findById(partnerId),
      ]);

      const callerName = caller?.name || 'Bạn tâm giao';
      const callerAvatar = caller?.avatar || null;
      const callId = randomUUID();

      const session: VoiceCallSession = {
        callId,
        callerId: senderId,
        calleeId: partnerId,
        callerName,
        callerAvatar,
        offerSdp: sdp,
        status: 'ringing',
        createdAt: new Date(),
      };

      // 30 giây timeout nếu không ai nhấc máy
      session.timeoutTimer = setTimeout(() => {
        const currentCall = this.activeCalls.get(callId);
        if (currentCall && currentCall.status === 'ringing') {
          this.logger.log(`[Call Timeout 30s] callId=${callId}, caller=${senderId}, callee=${partnerId}`);
          this.server.to(`user:${senderId}`).emit('voiceCallMissed', { callId, partnerId });
          this.server.to(`user:${partnerId}`).emit('voiceCallMissed', { callId, partnerId: senderId });
          this.cleanupCall(callId);
        }
      }, 30000);

      this.activeCalls.set(callId, session);
      this.userActiveCallMap.set(senderId, callId);
      this.userActiveCallMap.set(partnerId, callId);

      const callPayload = {
        callId,
        callerId: senderId,
        callerName,
        callerAvatar,
        sdp,
        timestamp: session.createdAt.toISOString(),
      };

      this.logger.log(`[VoiceCall Start] callId=${callId}, caller=${senderId}, callee=${partnerId}`);

      // Broadcast tới room user:{partnerId} (tất cả thiết bị của callee)
      this.server.to(`user:${partnerId}`).emit('incomingVoiceCall', callPayload);

      // Báo cho caller biết máy đối phương đang đổ chuông
      client.emit('voiceCallRinging', { callId, partnerId });

      // Kích hoạt Push Notification FCM để đánh thức máy người nhận (chỉ gửi metadata, KHÔNG gửi SDP qua FCM)
      if (partner?.fcmToken) {
        await this.firebaseNotificationService.sendPushNotification(
          partner.fcmToken,
          {
            title: `📞 Cuộc gọi thoại từ ${callerName}`,
            body: 'Đang gọi cho bạn • Chạm để trả lời',
            data: {
              type: 'incoming_voice_call',
              callId,
              callerId: senderId,
              callerName,
              callerAvatar: callerAvatar || '',
            },
            badgeCount: 1,
          },
        );
      }
    } catch (err) {
      this.logger.error('Lỗi khi bắt đầu cuộc gọi thoại', err);
      client.emit('errorMessage', { message: 'Không thể kết nối cuộc gọi lúc này' });
    }
  }

  /**
   * Người nhận chấp nhận cuộc gọi
   */
  @SubscribeMessage('acceptVoiceCall')
  handleAcceptVoiceCall(
    @ConnectedSocket() client: ChatSocket,
    @MessageBody() payload: { callId: string; callerId: string },
  ) {
    const receiverId = client.data.userId;
    if (!receiverId) return;

    const session = this.activeCalls.get(payload.callId);
    if (!session || session.calleeId !== receiverId || session.status !== 'ringing') {
      this.logger.warn(`Invalid acceptVoiceCall: callId=${payload.callId}, receiverId=${receiverId}`);
      return;
    }

    if (session.timeoutTimer) {
      clearTimeout(session.timeoutTimer);
      session.timeoutTimer = undefined;
    }
    session.status = 'connected';

    this.logger.log(`[VoiceCall Accepted] callId=${payload.callId}, caller=${payload.callerId}, callee=${receiverId}`);

    // Báo cho caller biết cuộc gọi đã được chấp nhận
    this.server.to(`user:${payload.callerId}`).emit('voiceCallAccepted', {
      callId: payload.callId,
      partnerId: receiverId,
    });

    // Báo cho các thiết bị khác của callee tắt chuông
    client.broadcast.to(`user:${receiverId}`).emit('voiceCallAnsweredElsewhere', {
      callId: payload.callId,
    });
  }

  /**
   * Người nhận từ chối cuộc gọi
   */
  @SubscribeMessage('rejectVoiceCall')
  handleRejectVoiceCall(
    @ConnectedSocket() client: ChatSocket,
    @MessageBody() payload: { callId: string; callerId: string; reason?: string },
  ) {
    const receiverId = client.data.userId;
    if (!receiverId) return;

    this.logger.log(`[VoiceCall Rejected] callId=${payload.callId}, caller=${payload.callerId}, callee=${receiverId}`);
    this.cleanupCall(payload.callId);
    this.userActiveCallMap.delete(receiverId);
    if (payload.callerId) {
      this.userActiveCallMap.delete(payload.callerId);
    }

    this.server.to(`user:${payload.callerId}`).emit('voiceCallRejected', {
      callId: payload.callId,
      partnerId: receiverId,
      reason: payload.reason || 'declined',
    });
  }

  /**
   * Một trong hai bên bấm cúp máy kết thúc cuộc gọi
   */
  @SubscribeMessage('endVoiceCall')
  handleEndVoiceCall(
    @ConnectedSocket() client: ChatSocket,
    @MessageBody() payload: { callId?: string; partnerId: string; reason?: string },
  ) {
    const senderId = client.data.userId;
    if (!senderId) return;

    const callId = payload.callId || this.userActiveCallMap.get(senderId);
    if (callId) {
      this.cleanupCall(callId);
    }
    this.userActiveCallMap.delete(senderId);
    if (payload.partnerId) {
      this.userActiveCallMap.delete(payload.partnerId);
    }

    this.logger.log(`[VoiceCall Ended] callId=${callId}, sender=${senderId}, partner=${payload.partnerId}`);
    this.server.to(`user:${payload.partnerId}`).emit('voiceCallEnded', {
      callId,
      partnerId: senderId,
      reason: payload.reason || 'user_hung_up',
    });
  }

  /**
   * WebRTC Signaling: Chuyển tiếp SDP Answer
   */
  @SubscribeMessage('webrtcAnswer')
  handleWebRtcAnswer(
    @ConnectedSocket() client: ChatSocket,
    @MessageBody() payload: { callId?: string; partnerId: string; sdp: any },
  ) {
    const senderId = client.data.userId;
    if (!senderId) return;

    this.server.to(`user:${payload.partnerId}`).emit('webrtcAnswer', {
      callId: payload.callId,
      senderId,
      sdp: payload.sdp,
    });
  }

  /**
   * WebRTC Signaling: Chuyển tiếp ICE Candidate
   */
  @SubscribeMessage('iceCandidate')
  handleIceCandidate(
    @ConnectedSocket() client: ChatSocket,
    @MessageBody() payload: { callId?: string; partnerId: string; candidate: any },
  ) {
    const senderId = client.data.userId;
    if (!senderId) return;

    this.server.to(`user:${payload.partnerId}`).emit('iceCandidate', {
      callId: payload.callId,
      senderId,
      candidate: payload.candidate,
    });
  }
}

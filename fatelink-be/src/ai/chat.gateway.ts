import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { AiService } from './ai.service';
import { MessageService } from '../message/message.service';
import { UsersService } from '../users/users.service';
import * as jwt from 'jsonwebtoken';

@WebSocketGateway({
  cors: {
    origin: '*', // Trong môi trường production bạn nên giới hạn origin cụ thể
  },
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server; // Thêm '!' để khắc phục lỗi "has no initializer"

  // Biến lưu trữ ánh xạ giữa UserID và SocketID hiện tại
  private activeUsers = new Map<string, string>();

  constructor(
    private readonly aiService: AiService,
    private readonly messageService: MessageService,
    private readonly usersService: UsersService,
  ) {}

  handleConnection(client: Socket) {
    try {
      // Lấy token từ handshake auth do Flutter gửi lên
      const token = client.handshake.auth?.token;
      // Bỏ qua check token nếu không có để code không bị crash, hoặc bạn có thể xử lý lỗi
      if (!token) { /* handle */ }

      // Giải mã token (Lưu ý: Thay 'YOUR_JWT_SECRET' bằng secret key trong .env của bạn)
      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret') as any;
      
      // Gắn userId vào client data để dùng cho các luồng nhắn tin sau này
      client.data.userId = decoded.sub || decoded.id || decoded.userId; 
      console.log(`🔌 Client connected: ${client.id} (User: ${client.data.userId})`);
      
      // Đánh dấu user đang online
      this.activeUsers.set(client.data.userId, client.id);
      
      // TỐI ƯU: Broadcast cho toàn bộ client biết user này vừa online
      this.server.emit('userStatusChanged', { userId: client.data.userId, isOnline: true });
    } catch (error: any) {
      console.log(`❌ Kết nối bị từ chối do Token không hợp lệ: ${client.id}`);
      client.disconnect(); // Ngắt kết nối ngay nếu không xác thực được
    }
  }

  handleDisconnect(client: Socket) {
    if (client.data.userId) {
      this.activeUsers.delete(client.data.userId); // Gỡ user khỏi danh sách online
      
      // TỐI ƯU: Broadcast cho toàn bộ client biết user này vừa offline
      this.server.emit('userStatusChanged', { userId: client.data.userId, isOnline: false });
    }
    console.log(`🔌 Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('sendMessage')
  async handleMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { text: string }, // Client chỉ cần gửi text
  ) {
    console.log(`📩 Nhận tin nhắn từ ${client.id}: ${payload.text}`);

    try {
      const userId = client.data.userId;
      if (!userId) {
        throw new Error('User không xác định');
      }

      // 2. Lưu tin nhắn của người dùng vào DB
      await this.messageService.createMessage(userId, payload.text, true);

      // 3. Lấy lịch sử chat từ DB (bảo mật và đáng tin cậy hơn)
      const dbHistory = await this.messageService.getHistoryForUser(userId, 20);
      const formattedHistory = this.aiService.formatHistoryForGemini(dbHistory);

      // Gọi Gemini AI thông qua Service
      const aiResponseRaw = await this.aiService.sendMessage(payload.text, formattedHistory);

      let aiText = aiResponseRaw;
      let isReadyToMatch = false;
      try {
        // Đảm bảo loại bỏ markdown code block nếu AI cố tình trả về markdown
        const cleanJsonString = aiResponseRaw.replace(/```json/gi, '').replace(/```/g, '').trim();
        const parsedData = JSON.parse(cleanJsonString);
        
        if (parsedData.reply) aiText = parsedData.reply;
        if (parsedData.is_ready_to_match) isReadyToMatch = true;

        // Cập nhật Cảm xúc & Tính cách vào DB
        if (parsedData.detected_emotions || parsedData.detected_personality) {
          // Gọi hàm updateUserTraits trong UsersService
          await this.usersService.updateUserTraits(
            userId,
            parsedData.detected_emotions,
            parsedData.detected_personality,
            parsedData.latestEmotion
          );
        }
      } catch (e: any) { // Khắc phục lỗi 'e' is of type 'unknown'
        console.warn('AI không trả về JSON hợp lệ, fallback dùng text thuần');
        console.error('Lỗi Parse JSON:', e.message);
      }

      // 4. Lưu tin nhắn của AI vào DB
      await this.messageService.createMessage(userId, aiText, false);

      // 5. Phát sự kiện 'receiveMessage' trả lời lại đúng client đó
      client.emit('receiveMessage', {
        text: aiText,
        isSentByMe: false,
        timestamp: new Date().toISOString(),
      });

      // 6. Nếu AI báo đã sẵn sàng ghép cặp (Kích hoạt Phase 2)
      if (isReadyToMatch) {
        client.emit('matchReady', { message: 'Faye đã hiểu bạn! Đang tìm kiếm định mệnh...' });
      }
    } catch (error: any) { // Khắc phục lỗi 'error' is of type 'unknown'
      console.error('❌ Lỗi khi xử lý tin nhắn trong ChatGateway:', error.stack || error.message);
      client.emit('errorMessage', {
        message: 'Faye đang bận chút việc, bạn thử lại sau nhé!',
      });
    }
  }

  // --- GIAO TIẾP 1-1 (GIỮA 2 USER THẬT) ---
  @SubscribeMessage('sendDirectMessage')
  async handleDirectMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { partnerId: string; text: string },
  ) {
    const senderId = client.data.userId;
    const { partnerId, text } = payload;

    // 1. TODO: Lưu tin nhắn thực tế vào DB (Bổ sung vào MessageService)
    // await this.messageService.createDirectMessage(senderId, partnerId, text);

    // 2. Tìm kiếm đối phương có đang Online không
    const targetSocketId = this.activeUsers.get(partnerId);

    if (targetSocketId) {
      // Đối phương đang mở app -> Bắn sự kiện realtime
      this.server.to(targetSocketId).emit('receiveDirectMessage', {
        senderId: senderId,
        text: text,
        timestamp: new Date().toISOString(),
      });
    } else {
      // Đối phương đang tắt app hoặc chạy nền -> Kích hoạt Push Notification
      console.log(`Người dùng ${partnerId} đang offline. Tiến hành gửi Push Notification.`);
    }
  }

  // --- TÍNH NĂNG TRẠNG THÁI ONLINE/OFFLINE ---
  @SubscribeMessage('checkUserStatus')
  handleCheckUserStatus(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { targetUserId: string },
  ) {
    const isOnline = this.activeUsers.has(payload.targetUserId);
    client.emit('userStatusResult', {
      userId: payload.targetUserId,
      isOnline: isOnline,
    });
  }

  // --- TÍNH NĂNG KIỂM TRA TRẠNG THÁI NHIỀU USER CÙNG LÚC ---
  @SubscribeMessage('checkUsersStatus')
  handleCheckUsersStatus(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { targetUserIds: string[] },
  ) {
    const statuses: Record<string, boolean> = {};
    if (payload.targetUserIds && Array.isArray(payload.targetUserIds)) {
      for (const id of payload.targetUserIds) {
        statuses[id] = this.activeUsers.has(id);
      }
    }
    client.emit('usersStatusResult', statuses);
  }

  // --- TÍNH NĂNG "ĐANG GÕ..." (TYPING) ---
  @SubscribeMessage('typing')
  handleTyping(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { partnerId: string; isTyping: boolean },
  ) {
    const targetSocketId = this.activeUsers.get(payload.partnerId);
    if (targetSocketId) {
      this.server.to(targetSocketId).emit('receiveTyping', {
        senderId: client.data.userId,
        isTyping: payload.isTyping,
      });
    }
  }
}
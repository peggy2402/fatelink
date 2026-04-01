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
import { GeminiService } from './gemini.service';
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
  server: Server;

  constructor(
    private readonly geminiService: GeminiService,
    private readonly messageService: MessageService,
    private readonly usersService: UsersService,
  ) {}

  handleConnection(client: Socket) {
    try {
      // Lấy token từ handshake auth do Flutter gửi lên
      const token = client.handshake.auth?.token;
      if (!token) throw new Error('Missing token');

      // Giải mã token (Lưu ý: Thay 'YOUR_JWT_SECRET' bằng secret key trong .env của bạn)
      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret') as any;
      
      // Gắn userId vào client data để dùng cho các luồng nhắn tin sau này
      client.data.userId = decoded.sub || decoded.id || decoded.userId; 
      console.log(`🔌 Client connected: ${client.id} (User: ${client.data.userId})`);
    } catch (error) {
      console.log(`❌ Kết nối bị từ chối do Token không hợp lệ: ${client.id}`);
      client.disconnect(); // Ngắt kết nối ngay nếu không xác thực được
    }
  }

  handleDisconnect(client: Socket) {
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
      const formattedHistory = this.geminiService.formatHistoryForGemini(dbHistory);

      // Gọi Gemini AI thông qua Service
      const aiResponseRaw = await this.geminiService.sendMessage(payload.text, formattedHistory);

      let aiText = aiResponseRaw;
      try {
        // Parse JSON từ AI
        const parsedData = JSON.parse(aiResponseRaw);
        if (parsedData.reply) aiText = parsedData.reply;

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
      } catch (e) {
        console.warn('AI không trả về JSON hợp lệ, fallback dùng text thuần');
      }

      // 4. Lưu tin nhắn của AI vào DB
      await this.messageService.createMessage(userId, aiText, false);

      // 5. Phát sự kiện 'receiveMessage' trả lời lại đúng client đó
      client.emit('receiveMessage', {
        text: aiText,
        isSentByMe: false,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      console.error('❌ Lỗi khi xử lý tin nhắn:', error);
      client.emit('errorMessage', {
        message: 'Faye đang bận chút việc, bạn thử lại sau nhé!',
      });
    }
  }
}
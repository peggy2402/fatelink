import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import * as admin from 'firebase-admin';

@Injectable()
export class NotificationService implements OnModuleInit {
  private readonly logger = new Logger(NotificationService.name);

  onModuleInit() {
    try {
      // Tránh lỗi khởi tạo lại Firebase nếu Module được nạp nhiều lần
      if (!admin.apps.length) {
        admin.initializeApp({
          credential: admin.credential.cert({
            projectId: process.env.FIREBASE_PROJECT_ID,
            clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
            // Replace để đảm bảo các ký tự xuống dòng \n được parse đúng chuẩn trong môi trường Linux/Docker
            privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
          }),
        });
        this.logger.log('Khởi tạo Firebase Admin thành công! 🚀');
      }
    } catch (error: any) {
      this.logger.error('Lỗi khi khởi tạo Firebase Admin:', error.message);
    }
  }

  // Hàm gọi FCM để gửi Push Notification
  async sendPushNotification(token: string, title: string, body: string, data?: Record<string, string>) {
    try {
      const response = await admin.messaging().send({
        token, // Device token của người dùng (lấy từ Flutter gửi lên)
        notification: { title, body },
        data: data || {}, // Dữ liệu đính kèm ngầm (Ví dụ: ID tin nhắn, ID người gửi)
      });
      this.logger.log(`Đã gửi Push Notification thành công: ${response}`);
      return response;
    } catch (error: any) {
      this.logger.error(`Gửi Push Notification thất bại: ${error.message}`);
      // Không throw error để tránh làm sập luồng gửi tin nhắn chính
      return null;
    }
  }
}
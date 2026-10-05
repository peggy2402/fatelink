import { Injectable, Logger } from '@nestjs/common';
import * as admin from 'firebase-admin';

export interface PushNotificationPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
  badgeCount?: number;
}

@Injectable()
export class FirebaseNotificationService {
  private readonly logger = new Logger(FirebaseNotificationService.name);
  private firebaseApp: admin.app.App | null = null;
  private isInitialized = false;

  constructor() {
    this.initFirebase();
  }

  private initFirebase() {
    try {
      const projectId = process.env.FIREBASE_PROJECT_ID;
      const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
      let privateKey = process.env.FIREBASE_PRIVATE_KEY;

      if (!projectId || !clientEmail || !privateKey) {
        this.logger.warn(
          'Firebase credentials (FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY) are missing in environment variables. FCM Push notifications will be skipped.',
        );
        return;
      }

      if (privateKey.includes('\\n')) {
        privateKey = privateKey.replace(/\\n/g, '\n');
      }

      if (admin.apps.length > 0) {
        this.firebaseApp = admin.app();
      } else {
        this.firebaseApp = admin.initializeApp({
          credential: admin.credential.cert({
            projectId,
            clientEmail,
            privateKey,
          }),
        });
      }

      this.isInitialized = true;
      this.logger.log(
        `Firebase Admin initialized successfully for project: ${projectId}`,
      );
    } catch (error) {
      this.logger.error(
        'Failed to initialize Firebase Admin',
        error instanceof Error ? error.stack : String(error),
      );
    }
  }

  /**
   * Gửi thông báo đẩy FCM tới thiết bị Android
   * Tự động gắn Channel ưu tiên cao, hiển thị màn hình khóa và huy hiệu số đếm (Badge)
   */
  async sendPushNotification(
    fcmToken: string,
    payload: PushNotificationPayload,
  ): Promise<boolean> {
    if (!this.isInitialized || !this.firebaseApp) {
      this.logger.debug(
        `Firebase not initialized, skipping push notification for token: ${fcmToken?.slice(0, 10)}...`,
      );
      return false;
    }

    if (!fcmToken || typeof fcmToken !== 'string' || fcmToken.trim().length === 0) {
      return false;
    }

    try {
      const message: admin.messaging.Message = {
        token: fcmToken,
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: {
          ...payload.data,
          title: payload.title,
          body: payload.body,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'fatelink_high_importance_channel',
            sound: 'default',
            defaultSound: true,
            defaultVibrateTimings: true,
            visibility: 'public', // Cho phép hiển thị trên màn hình khóa (Lock screen)
            notificationCount: payload.badgeCount ?? 1, // Huy hiệu số đếm icon ứng dụng
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
      };

      const response = await admin.messaging(this.firebaseApp).send(message);
      this.logger.log(`Push notification sent successfully: ${response}`);
      return true;
    } catch (error: any) {
      this.logger.warn(
        `Failed to send FCM push notification: ${error?.message || error}`,
      );
      return false;
    }
  }
}

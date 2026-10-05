import dotenv from 'dotenv';
import admin from 'firebase-admin';
import mongoose from 'mongoose';

dotenv.config();

const projectId = process.env.FIREBASE_PROJECT_ID;
const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
let privateKey = process.env.FIREBASE_PRIVATE_KEY;

if (!projectId || !clientEmail || !privateKey) {
  console.error('❌ Thiếu thông tin cấu hình Firebase trong .env');
  process.exit(1);
}

if (privateKey.includes('\\n')) {
  privateKey = privateKey.replace(/\\n/g, '\n');
}

// Khởi tạo Firebase Admin
try {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId,
      clientEmail,
      privateKey,
    }),
  });
  console.log(`✅ Đã kết nối Firebase Admin thành công (Project: ${projectId})`);
} catch (err) {
  console.error('❌ Lỗi khởi tạo Firebase Admin:', err.message);
  process.exit(1);
}

async function getTargetFcmToken() {
  const cliToken = process.argv[2];
  if (cliToken && cliToken.trim().length > 0) {
    return { token: cliToken.trim(), source: 'CLI Argument' };
  }

  // Nếu không truyền token, tự tìm user mới nhất có fcmToken trong MongoDB
  if (process.env.MONGODB_URI) {
    try {
      console.log('🔍 Đang tìm kiếm FCM token người dùng gần nhất trong database...');
      await mongoose.connect(process.env.MONGODB_URI);
      const user = await mongoose.connection.collection('users').findOne(
        { fcmToken: { $exists: true, $ne: '' } },
        { sort: { updatedAt: -1 } }
      );
      await mongoose.disconnect();

      if (user && user.fcmToken) {
        return {
          token: user.fcmToken,
          source: `User: ${user.name || user.email || user._id}`,
        };
      }
    } catch (dbErr) {
      console.warn('⚠️ Không thể đọc database để lấy token tự động:', dbErr.message);
    }
  }

  return null;
}

async function run() {
  const target = await getTargetFcmToken();

  if (!target || !target.token) {
    console.log(`
👉 HƯỚNG DẪN TEST THÔNG BÁO ĐẨY FCM:
1. Mở ứng dụng Flutter trên máy Android thật hoặc máy ảo (Android Emulator).
2. Nhìn vào log terminal (khi chạy flutter run): Tìm dòng '📱 [FcmService] FCM Token: ...'
3. Chạy lệnh:
   node tools/test-fcm-push.mjs <FCM_TOKEN_CỦA_BẠN>
    `);
    process.exit(0);
  }

  console.log(`🚀 Đang gửi thông báo thử nghiệm tới: [${target.source}]`);
  console.log(`📱 Token: ${target.token.slice(0, 20)}...${target.token.slice(-10)}`);

  const message = {
    token: target.token,
    notification: {
      title: '✨ FateLink Cosmic Soulmate',
      body: 'Có một người bạn định mệnh vừa gửi tín hiệu tần số đến bạn! 💕',
    },
    data: {
      partnerId: '60d0fe4f5311236168a109ca',
      partnerName: 'Cosmic Soulmate',
      type: 'direct_chat',
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'fatelink_high_importance_channel',
        sound: 'default',
        defaultSound: true,
        defaultVibrateTimings: true,
        visibility: 'public', // Hiển thị trên màn hình khóa (Lock screen)
        notificationCount: 3, // Hiển thị huy hiệu số 3 trên icon ứng dụng
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('\n🎉 THÀNH CÔNG RỰC RỠ!');
    console.log('✅ Message ID:', response);
    console.log('📲 Hãy kiểm tra điện thoại Android:');
    console.log('   1. Banner Heads-Up nổi thả xuống trên đỉnh màn hình.');
    console.log('   2. Khóa màn hình để thấy thông báo hiển thị ở Lock Screen.');
    console.log('   3. Ra màn hình chính (Home) để kiểm tra huy hiệu số đếm (Badge) trên icon app!');
  } catch (error) {
    console.error('\n❌ Gửi thông báo thất bại:', error.message);
    if (error.code) {
      console.error('Mã lỗi Firebase:', error.code);
    }
  }
}

run();

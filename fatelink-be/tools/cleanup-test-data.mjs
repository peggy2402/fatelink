import dotenv from 'dotenv';
import mongoose from 'mongoose';
import { v2 as cloudinary } from 'cloudinary';

dotenv.config();

async function cleanup() {
  console.log('🧹 [Cleanup] Bắt đầu dọn dẹp dữ liệu test trên Production...');

  // 1. Dọn dẹp MongoDB
  const mongoUri = process.env.MONGODB_URI;
  if (!mongoUri) {
    throw new Error('Thiếu MONGODB_URI trong .env');
  }

  await mongoose.connect(mongoUri);
  console.log('✅ Đã kết nối MongoDB Atlas');

  const db = mongoose.connection.db;

  // Xóa tin nhắn test với clientMessageId: test_msg_idem_001 hoặc gửi giữa 2 user test
  const deleteMessagesResult = await db.collection('messages').deleteMany({
    $or: [
      { clientMessageId: 'test_msg_idem_001' },
      { senderId: '6ac0ab39c7db16c6939da703', recipientId: '6ac0ab39c7db16c6939da704' },
      { userId: '6ac0ab39c7db16c6939da703', partnerId: '6ac0ab39c7db16c6939da704' },
      { userId: '6ac0ab39c7db16c6939da704', partnerId: '6ac0ab39c7db16c6939da703' },
    ],
  });
  console.log(`✅ Đã xóa ${deleteMessagesResult.deletedCount} tin nhắn test trong collection 'messages'`);

  // Xóa session test nếu có trong sessions / users
  if (db.collection('sessions')) {
    const deleteSessionResult = await db.collection('sessions').deleteMany({
      sessionId: 'session_test_voice_123',
    });
    console.log(`✅ Đã xóa ${deleteSessionResult.deletedCount} session test trong collection 'sessions'`);
  }

  await mongoose.disconnect();
  console.log('✅ Đã ngắt kết nối MongoDB');

  // 2. Dọn dẹp Cloudinary
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME || 'zp6cgw5b',
    api_key: process.env.CLOUDINARY_API_KEY || '392944746644295',
    api_secret: process.env.CLOUDINARY_API_SECRET || 'zMjH7Ng6kQLTx_EUCHhGdCUlHP8',
    secure: true,
  });

  try {
    const cloudRes = await cloudinary.uploader.destroy('fatelink/voice_notes/sample', {
      resource_type: 'video',
    });
    console.log('✅ Đã xóa file test sample.m4a trên Cloudinary:', cloudRes);
  } catch (err) {
    console.warn('⚠️ Lỗi xóa Cloudinary sample:', err.message);
  }

  console.log('🎉 [Cleanup] Dọn dẹp dữ liệu test hoàn tất!');
}

cleanup().catch((err) => {
  console.error('❌ Lỗi dọn dẹp:', err);
  process.exit(1);
});

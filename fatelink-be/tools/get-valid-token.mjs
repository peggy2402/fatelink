import dotenv from 'dotenv';
import mongoose from 'mongoose';
import jwt from 'jsonwebtoken';

dotenv.config();

async function run() {
  await mongoose.connect(process.env.MONGODB_URI);
  const user = await mongoose.connection.collection('users').findOne({});
  if (!user) {
    console.error('No user found');
    await mongoose.disconnect();
    return;
  }

  const userIdStr = user._id.toString();
  const sessionId = 'session_test_voice_123';

  await mongoose.connection.collection('authsessions').updateOne(
    { sessionId },
    {
      $set: {
        sessionId,
        userId: userIdStr,
        deviceType: 'mobile',
        deviceId: 'test-device-id',
        status: 'active',
        lastSeenAt: new Date(),
        updatedAt: new Date(),
        createdAt: new Date(),
      },
    },
    { upsert: true }
  );

  const token = jwt.sign(
    {
      sub: userIdStr,
      sessionId,
      role: 'user',
    },
    process.env.JWT_SECRET,
    { expiresIn: '30d' }
  );

  console.log('USER_ID=' + userIdStr);
  console.log('VALID_TOKEN=' + token);
  await mongoose.disconnect();
}

run().catch(console.error);

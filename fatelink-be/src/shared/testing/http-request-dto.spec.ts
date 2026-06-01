import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { GoogleLoginDto } from '@contexts/auth/presentation/http/dtos/auth.request.dto';
import { SendAiMessageDto } from '@contexts/chat/presentation/http/dtos/chat-ai.request.dto';
import { UpdateFcmTokenDto } from '@contexts/users/presentation/http/dtos/users.request.dto';

describe('HTTP request DTOs', () => {
  it('rejects empty google token', async () => {
    const dto = plainToInstance(GoogleLoginDto, { token: '' });
    const errors = await validate(dto);

    expect(errors).not.toHaveLength(0);
  });

  it('accepts valid AI chat payload', async () => {
    const dto = plainToInstance(SendAiMessageDto, {
      message: 'Xin chao',
      history: [{ text: 'Hello', isSentByMe: true }],
    });
    const errors = await validate(dto);

    expect(errors).toHaveLength(0);
  });

  it('rejects invalid FCM token payload', async () => {
    const dto = plainToInstance(UpdateFcmTokenDto, { fcmToken: '' });
    const errors = await validate(dto);

    expect(errors).not.toHaveLength(0);
  });
});

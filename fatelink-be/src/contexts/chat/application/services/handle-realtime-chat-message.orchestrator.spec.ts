import { HandleRealtimeChatMessageOrchestrator } from './handle-realtime-chat-message.orchestrator';

describe('HandleRealtimeChatMessageOrchestrator', () => {
  it('persists user message, updates traits, persists AI reply, and returns match state', async () => {
    const createAiMessageHandler = {
      execute: jest.fn().mockResolvedValue(undefined),
    };
    const getAiChatHistoryHandler = {
      execute: jest
        .fn()
        .mockResolvedValue([
          { text: 'Xin chao', isSentByMe: true, timestamp: new Date() },
        ]),
    };
    const sendAiMessageHandler = {
      execute: jest.fn().mockResolvedValue(
        JSON.stringify({
          reply: 'Minh o day',
          latestEmotion: 'Binh yen',
          detected_emotions: { stress: 3, warmth: 8 },
          detected_personality: [6, 5, 4],
          is_ready_to_match: true,
        }),
      ),
    };
    const updateUserTraitsHandler = {
      execute: jest.fn().mockResolvedValue(undefined),
    };

    const orchestrator = new HandleRealtimeChatMessageOrchestrator(
      createAiMessageHandler,
      getAiChatHistoryHandler,
      sendAiMessageHandler,
      updateUserTraitsHandler,
    );

    const result = await orchestrator.execute({
      userId: 'user-1',
      text: 'Hom nay minh met',
    });

    expect(createAiMessageHandler.execute).toHaveBeenNthCalledWith(1, {
      userId: 'user-1',
      text: 'Hom nay minh met',
      isSentByMe: true,
    });
    expect(updateUserTraitsHandler.execute).toHaveBeenCalledWith({
      userId: 'user-1',
      emotions: { stress: 3, warmth: 8 },
      personality: [6, 5, 4],
      latestEmotion: 'Binh yen',
    });
    expect(createAiMessageHandler.execute).toHaveBeenNthCalledWith(2, {
      userId: 'user-1',
      text: 'Minh o day',
      isSentByMe: false,
    });
    expect(result).toEqual({
      reply: 'Minh o day',
      isReadyToMatch: true,
    });
  });

  it('falls back to raw AI text when response is not JSON', async () => {
    const orchestrator = new HandleRealtimeChatMessageOrchestrator(
      {
        execute: jest.fn().mockResolvedValue(undefined),
      },
      {
        execute: jest.fn().mockResolvedValue([]),
      },
      {
        execute: jest.fn().mockResolvedValue('raw ai reply'),
      },
      {
        execute: jest.fn().mockResolvedValue(undefined),
      },
    );

    const result = await orchestrator.execute({
      userId: 'user-2',
      text: 'Ping',
    });

    expect(result).toEqual({
      reply: 'raw ai reply',
      isReadyToMatch: false,
    });
  });
});

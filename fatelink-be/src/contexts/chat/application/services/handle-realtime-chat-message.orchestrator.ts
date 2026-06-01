import type {
  HandleRealtimeChatMessageCommand,
  HandleRealtimeChatMessageResult,
} from '@contexts/chat/application/contracts/chat.commands';
import type {
  CreateAiMessageHandler,
  GetAiChatHistoryHandler,
  SendAiMessageHandler,
} from '@contexts/chat/application/contracts/chat.handlers';
import type { EmotionVector } from '@shared/kernel/emotion-vector';
import type {
  UpdateUserTraitsCommand,
  UpdateUserTraitsHandler,
} from '@contexts/users/application/contracts/update-user-traits.contract';

type AiStructuredResponse = {
  reply?: string;
  isReadyToMatch?: boolean;
  emotions?: Partial<EmotionVector>;
  personality?: number[];
  latestEmotion?: string;
};

export class HandleRealtimeChatMessageOrchestrator {
  constructor(
    private readonly createAiMessageHandler: CreateAiMessageHandler,
    private readonly getAiChatHistoryHandler: GetAiChatHistoryHandler,
    private readonly sendAiMessageHandler: SendAiMessageHandler,
    private readonly updateUserTraitsHandler: UpdateUserTraitsHandler,
  ) {}

  async execute(
    input: HandleRealtimeChatMessageCommand,
  ): Promise<HandleRealtimeChatMessageResult> {
    await this.createAiMessageHandler.execute({
      userId: input.userId,
      text: input.text,
      isSentByMe: true,
    });

    const dbHistory = await this.getAiChatHistoryHandler.execute({
      userId: input.userId,
      limit: 20,
    });

    const aiResponseRaw = await this.sendAiMessageHandler.execute({
      message: input.text,
      history: dbHistory,
    });

    let aiText = aiResponseRaw;
    let isReadyToMatch = false;
    let parsedData: AiStructuredResponse | null = null;

    try {
      const cleanJsonString = aiResponseRaw
        .replace(/```json/gi, '')
        .replace(/```/g, '')
        .trim();
      parsedData = this.parseAiResponse(cleanJsonString);
    } catch {
      // Fallback to raw AI text when the model does not return structured JSON.
    }

    if (parsedData?.reply) {
      aiText = parsedData.reply;
    }
    if (parsedData?.isReadyToMatch) {
      isReadyToMatch = true;
    }

    const traitsUpdate = this.toTraitsUpdate(input.userId, parsedData);
    if (traitsUpdate) {
      await this.updateUserTraitsHandler.execute(traitsUpdate);
    }

    await this.createAiMessageHandler.execute({
      userId: input.userId,
      text: aiText,
      isSentByMe: false,
    });

    return {
      reply: aiText,
      isReadyToMatch,
    };
  }

  private toTraitsUpdate(
    userId: string,
    parsedData: AiStructuredResponse | null,
  ): UpdateUserTraitsCommand | null {
    if (!parsedData?.emotions && !parsedData?.personality) {
      return null;
    }

    return {
      userId,
      emotions: parsedData.emotions,
      personality: parsedData.personality,
      latestEmotion: parsedData.latestEmotion,
    };
  }

  private parseAiResponse(json: string): AiStructuredResponse | null {
    const parsed: unknown = JSON.parse(json);
    if (!this.isRecord(parsed)) {
      return null;
    }

    return {
      reply: typeof parsed.reply === 'string' ? parsed.reply : undefined,
      isReadyToMatch: parsed.is_ready_to_match === true,
      emotions: this.isEmotionVector(parsed.detected_emotions)
        ? parsed.detected_emotions
        : undefined,
      personality: this.isNumberArray(parsed.detected_personality)
        ? parsed.detected_personality
        : undefined,
      latestEmotion:
        typeof parsed.latestEmotion === 'string'
          ? parsed.latestEmotion
          : undefined,
    };
  }

  private isRecord(value: unknown): value is Record<string, unknown> {
    return typeof value === 'object' && value !== null;
  }

  private isEmotionVector(value: unknown): value is Partial<EmotionVector> {
    return this.isRecord(value);
  }

  private isNumberArray(value: unknown): value is number[] {
    return (
      Array.isArray(value) && value.every((item) => typeof item === 'number')
    );
  }
}

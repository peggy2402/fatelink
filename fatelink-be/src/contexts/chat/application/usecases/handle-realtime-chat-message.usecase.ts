import type {
  HandleRealtimeChatMessageCommand,
  HandleRealtimeChatMessageResult,
} from '@contexts/chat/application/contracts/chat.commands';
import type { HandleRealtimeChatMessageOrchestrator } from '@contexts/chat/application/services/handle-realtime-chat-message.orchestrator';

export class HandleRealtimeChatMessageUseCase {
  constructor(
    private readonly orchestrator: HandleRealtimeChatMessageOrchestrator,
  ) {}

  async execute(
    input: HandleRealtimeChatMessageCommand,
  ): Promise<HandleRealtimeChatMessageResult> {
    return this.orchestrator.execute(input);
  }
}

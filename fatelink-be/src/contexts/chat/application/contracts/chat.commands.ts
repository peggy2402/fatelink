export interface ChatHistoryItem {
  text: string;
  isSentByMe: boolean;
}

export interface SendChatMessageCommand {
  message: string;
  history?: ChatHistoryItem[];
}

export interface PersistChatMessageCommand {
  userId: string;
  text: string;
  isSentByMe: boolean;
}

export interface LoadChatHistoryQuery {
  userId: string;
  limit?: number;
}

export interface HandleRealtimeChatMessageCommand {
  userId: string;
  text: string;
}

export interface HandleRealtimeChatMessageResult {
  reply: string;
  isReadyToMatch: boolean;
}

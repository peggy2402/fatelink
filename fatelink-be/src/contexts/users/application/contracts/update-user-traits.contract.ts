export interface UpdateUserTraitsCommand {
  userId: string;
  emotions?: {
    stress?: number;
    loneliness?: number;
    sadness?: number;
    calmness?: number;
    warmth?: number;
    happiness?: number;
  };
  personality?: number[];
  latestEmotion?: string;
}

export interface UpdateUserTraitsHandler {
  execute(input: UpdateUserTraitsCommand): Promise<void>;
}

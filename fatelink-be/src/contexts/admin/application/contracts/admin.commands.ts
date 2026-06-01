export interface CreateAiModelCommand {
  modelId: string;
  providerName: string;
  displayName: string;
  isEnabled: boolean;
  priority: number;
}

export interface UpdateAiModelCommand {
  id: string;
  modelId?: string;
  providerName?: string;
  displayName?: string;
  isEnabled?: boolean;
  priority?: number;
}

export interface UpdateSystemConfigCommand {
  systemPrompt?: string;
  additionalKnowledge?: string;
  onboardingMessageLimit?: number;
}

export interface ReorderAiModelsCommand {
  modelIds: string[];
}

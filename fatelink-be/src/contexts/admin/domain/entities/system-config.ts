export class SocialProviderConfig {
  enabled!: boolean;
  appId?: string;
  clientId?: string;
  clientToken?: string;
  appSecret?: string;
  clientKey?: string;
  secretKey?: string;
}

export class SocialAuthConfig {
  facebook?: {
    enabled: boolean;
    appId: string;
    clientToken: string;
    appSecret?: string;
  };
  google?: {
    enabled: boolean;
    clientId: string;
    iosClientId?: string;
  };
  zalo?: {
    enabled: boolean;
    appId: string;
    secretKey?: string;
  };
  tiktok?: {
    enabled: boolean;
    clientKey: string;
    clientSecret?: string;
  };
}

export class SystemConfig {
  id?: string;
  systemPrompt!: string;
  additionalKnowledge!: string;
  onboardingMessageLimit!: number;
  socialAuth?: SocialAuthConfig;
}

import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type SystemConfigDocument = SystemConfig & Document;

@Schema({ timestamps: true })
export class SystemConfig {
  @Prop({
    default:
      'Bạn là Faye - một AI thấu hiểu cảm xúc. Hãy trò chuyện ngắn gọn, tự nhiên và thân thiện...',
  })
  systemPrompt!: string;

  @Prop({ default: '' })
  additionalKnowledge!: string;

  @Prop({ default: 10 })
  onboardingMessageLimit!: number;

  @Prop({
    type: Object,
    default: {
      facebook: {
        enabled: true,
        appId: '',
        clientToken: '',
        appSecret: '',
      },
      google: {
        enabled: true,
        clientId: '918573554808-07stv5tp2474icsh5f47mvop9vaa9sug.apps.googleusercontent.com',
        iosClientId: '',
      },
      zalo: {
        enabled: true,
        appId: '3205454775701109337',
        secretKey: '',
      },
      tiktok: {
        enabled: true,
        clientKey: '',
        clientSecret: '',
      },
    },
  })
  socialAuth?: {
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
  };
}

export const SystemConfigSchema = SchemaFactory.createForClass(SystemConfig);

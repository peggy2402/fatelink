export interface EmailDeliveryService {
  sendMagicLink(input: {
    to: string;
    subject: string;
    magicLink: string;
    expiresAt: Date;
    name?: string;
  }): Promise<void>;
}

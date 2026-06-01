export interface SupportNotificationPayload {
  name: string;
  email: string;
  content: string;
}

export interface SupportNotifierService {
  submit(request: SupportNotificationPayload): Promise<void>;
}

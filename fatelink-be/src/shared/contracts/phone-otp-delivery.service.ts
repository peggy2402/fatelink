export interface PhoneOtpDeliveryService {
  sendOtp(input: {
    phoneNumber: string;
    otpCode: string;
    requestId: string;
  }): Promise<void>;
}

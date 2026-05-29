import { DeviceType } from './v2/dto/device-type.enum';

export interface AuthJwtPayload {
  sub: string;
  email: string;
  tokenVersion: number;
  deviceType?: DeviceType;
}

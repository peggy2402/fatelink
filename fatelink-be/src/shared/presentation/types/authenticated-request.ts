import { type Request } from 'express';
import { type AuthenticatedUser } from '@shared/contracts/authenticated-user';

export interface AuthenticatedRequest extends Request {
  user: AuthenticatedUser;
}

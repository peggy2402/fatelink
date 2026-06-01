export interface AdminCredentialService {
  validate(username: string, password: string): boolean;
}

export class CreateUserDto {
  readonly email: string;
  readonly name?: string;
  readonly avatar?: string;
  readonly googleId: string;
}
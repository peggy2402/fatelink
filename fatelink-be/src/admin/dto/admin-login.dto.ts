import { IsString, IsNotEmpty } from 'class-validator';

export class AdminLoginDto {
  @IsString()
  @IsNotEmpty({ message: 'Tài khoản không được để trống' })
  username!: string;

  @IsString()
  @IsNotEmpty({ message: 'Mật khẩu không được để trống' })
  password!: string;
}

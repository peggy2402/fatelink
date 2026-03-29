import { IsEmail, IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class CreateSupportDto {
  @IsString()
  @IsNotEmpty({ message: 'Vui lòng nhập họ và tên' })
  readonly name: string;

  @IsEmail({}, { message: 'Email không hợp lệ' })
  @IsNotEmpty({ message: 'Vui lòng nhập email' })
  readonly email: string;

  @IsString()
  @IsNotEmpty({ message: 'Vui lòng nhập nội dung hỗ trợ' })
  @MaxLength(2000, { message: 'Nội dung hỗ trợ không được vượt quá 2000 ký tự' })
  readonly content: string;
}
import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class UploadImageDto {
  @ApiProperty({
    description: 'Chuỗi Base64 Data URI (data:image/jpeg;base64,...) hoặc URL ảnh cần upload',
    example: 'data:image/jpeg;base64,...',
  })
  @IsString()
  @IsNotEmpty()
  image!: string;

  @ApiProperty({
    description: 'Thư mục trên Cloudinary để lưu ảnh',
    example: 'fatelink/vibes',
    required: false,
  })
  @IsOptional()
  @IsString()
  folder?: string;
}

export class DeleteImageDto {
  @ApiProperty({
    description: 'Public ID của ảnh trên Cloudinary cần xóa',
    example: 'fatelink/vibes/sample_123',
  })
  @IsString()
  @IsNotEmpty()
  publicId!: string;
}

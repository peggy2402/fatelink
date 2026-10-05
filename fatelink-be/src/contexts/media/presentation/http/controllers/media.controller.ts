import {
  Body,
  Controller,
  Delete,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '@contexts/auth/presentation/http/guards/jwt-auth.guard';
import { CloudinaryService } from '@contexts/media/infrastructure/services/cloudinary.service';
import { DeleteImageDto, UploadImageDto, UploadVoiceDto } from '../dtos/upload-image.dto';

@ApiTags('Media & Upload')
@Controller('upload')
export class MediaController {
  constructor(private readonly cloudinaryService: CloudinaryService) {}

  @Post('image')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Tải ảnh lên Cloudinary CDN (Hỗ trợ Base64 & URL)' })
  @ApiResponse({
    status: 201,
    description: 'Ảnh được tải lên Cloudinary thành công, trả về HTTPS URL tối ưu.',
  })
  async uploadImage(@Body() dto: UploadImageDto) {
    const result = await this.cloudinaryService.uploadImage(
      dto.image,
      dto.folder || 'fatelink/vibes',
    );
    return {
      success: true,
      data: result,
    };
  }

  @Post('voice')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Tải tin nhắn thoại Voice Note lên Cloudinary CDN' })
  @ApiResponse({
    status: 201,
    description: 'Tin nhắn thoại được tải lên Cloudinary thành công, trả về HTTPS URL.',
  })
  async uploadVoice(@Body() dto: UploadVoiceDto) {
    const result = await this.cloudinaryService.uploadAudio(
      dto.audio,
      dto.folder || 'fatelink/voice_notes',
    );
    return {
      success: true,
      data: result,
    };
  }

  @Delete('image')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Xóa ảnh vĩnh viễn khỏi Cloudinary để tiết kiệm dung lượng' })
  @ApiResponse({
    status: 200,
    description: 'Xóa ảnh thành công.',
  })
  async deleteImage(@Body() dto: DeleteImageDto) {
    const success = await this.cloudinaryService.deleteImage(dto.publicId);
    return {
      success,
      message: success
        ? 'Ảnh đã được xóa khỏi Cloudinary.'
        : 'Không thể xóa ảnh hoặc ảnh không tồn tại.',
    };
  }
}

import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiConsumes, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
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
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fileSize: 10 * 1024 * 1024 }, // 10MB giới hạn tối đa
    }),
  )
  @ApiConsumes('multipart/form-data', 'application/json')
  @ApiOperation({ summary: 'Tải tin nhắn thoại Voice Note lên Cloudinary CDN (Multipart/Form-Data hoặc Base64)' })
  @ApiResponse({
    status: 201,
    description: 'Tin nhắn thoại được tải lên Cloudinary thành công, trả về HTTPS URL.',
  })
  async uploadVoice(
    @UploadedFile() file?: Express.Multer.File,
    @Body() dto?: UploadVoiceDto,
  ) {
    // 1. Ưu tiên xử lý Multipart File Upload (chuẩn Telegram / WhatsApp)
    if (file && file.buffer) {
      const allowedExts = /\.(m4a|aac|mp3|ogg|wav|webm)$/i;
      const isAudioMime = file.mimetype.startsWith('audio/') || file.mimetype === 'video/mp4' || file.mimetype === 'application/octet-stream';
      if (!isAudioMime && !allowedExts.test(file.originalname)) {
        throw new BadRequestException('Định dạng tệp không hợp lệ. Vui lòng tải lên tệp âm thanh (.m4a, .mp3, .aac, .wav).');
      }

      const result = await this.cloudinaryService.uploadAudioBuffer(
        file.buffer,
        dto?.folder || 'fatelink/voice_notes',
        file.originalname,
      );

      return {
        success: true,
        data: result,
      };
    }

    // 2. Fallback xử lý Base64 DTO nếu client cũ gửi JSON
    if (dto && dto.audio) {
      const result = await this.cloudinaryService.uploadAudio(
        dto.audio,
        dto.folder || 'fatelink/voice_notes',
      );
      return {
        success: true,
        data: result,
      };
    }

    throw new BadRequestException('Vui lòng đính kèm tệp âm thanh (field "file") hoặc dữ liệu base64.');
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

import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Logger,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiConsumes, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '@contexts/auth/presentation/http/guards/jwt-auth.guard';
import { CloudinaryService } from '@contexts/media/infrastructure/services/cloudinary.service';
import { DeleteImageDto, UploadImageDto } from '../dtos/upload-image.dto';

@ApiTags('Media & Upload')
@Controller('upload')
export class MediaController {
  private readonly logger = new Logger(MediaController.name);

  constructor(private readonly cloudinaryService: CloudinaryService) {}

  @Post('image')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fileSize: 15 * 1024 * 1024 }, // 15MB giới hạn tối đa
    }),
  )
  @ApiConsumes('multipart/form-data', 'application/json')
  @ApiOperation({ summary: 'Tải ảnh lên Cloudinary CDN (Hỗ trợ Multipart File, Base64 & URL)' })
  @ApiResponse({
    status: 201,
    description: 'Ảnh được tải lên Cloudinary thành công, trả về HTTPS URL tối ưu.',
  })
  async uploadImage(
    @UploadedFile() file?: Express.Multer.File,
    @Body() body?: any,
  ) {
    if (file) {
      this.logger.log(
        `[Multipart Image] Nhận file: ${file.originalname}, mimetype: ${file.mimetype}, size: ${file.size} bytes`,
      );
      const folder = body?.folder || 'fatelink/vibes';
      const result = await this.cloudinaryService.uploadImageBuffer(
        file.buffer,
        folder,
        file.originalname,
      );
      return {
        success: true,
        data: result,
      };
    }

    if (body?.image) {
      const result = await this.cloudinaryService.uploadImage(
        body.image,
        body.folder || 'fatelink/vibes',
      );
      return {
        success: true,
        data: result,
      };
    }

    throw new BadRequestException('Vui lòng cung cấp file ảnh hoặc chuỗi base64');
  }

  @Post('voice')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fileSize: 10 * 1024 * 1024 }, // 10MB giới hạn tối đa
    }),
  )
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Tải tin nhắn thoại Voice Note lên Cloudinary CDN (Multipart/Form-Data)' })
  @ApiResponse({
    status: 201,
    description: 'Tin nhắn thoại được tải lên Cloudinary thành công, trả về HTTPS URL.',
  })
  async uploadVoice(
    @UploadedFile() file: Express.Multer.File,
    @Body('folder') folder?: string,
  ) {
    if (!file || !file.buffer) {
      this.logger.warn('[UploadVoice] Request missing file or empty buffer');
      throw new BadRequestException('Vui lòng đính kèm tệp âm thanh trong trường "file".');
    }

    this.logger.log(
      `[UploadVoice] Nhận tệp: ${file.originalname}, mimetype: ${file.mimetype}, size: ${file.size} bytes`,
    );

    const allowedExts = /\.(m4a|aac|mp3|ogg|wav|webm)$/i;
    const isAudioMime =
      file.mimetype.startsWith('audio/') ||
      file.mimetype === 'video/mp4' ||
      file.mimetype === 'application/octet-stream';

    if (!isAudioMime && !allowedExts.test(file.originalname)) {
      this.logger.warn(`[UploadVoice] File rejected: mimetype=${file.mimetype}, name=${file.originalname}`);
      throw new BadRequestException(
        'Định dạng tệp không hợp lệ. Vui lòng tải lên tệp âm thanh (.m4a, .mp3, .aac, .wav).',
      );
    }

    const result = await this.cloudinaryService.uploadAudioBuffer(
      file.buffer,
      folder || 'fatelink/voice_notes',
      file.originalname,
    );

    this.logger.log(`[UploadVoice] Thành công Cloudinary URL: ${result.url}`);

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

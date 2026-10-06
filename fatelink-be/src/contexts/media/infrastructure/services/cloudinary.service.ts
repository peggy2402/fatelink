import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { v2 as cloudinary, UploadApiResponse } from 'cloudinary';

@Injectable()
export class CloudinaryService {
  private readonly logger = new Logger(CloudinaryService.name);

  constructor(private readonly configService: ConfigService) {
    const cloudName =
      this.configService.get<string>('CLOUDINARY_CLOUD_NAME') || 'zp6cgw5b';
    const apiKey =
      this.configService.get<string>('CLOUDINARY_API_KEY') || '392944746644295';
    const apiSecret =
      this.configService.get<string>('CLOUDINARY_API_SECRET') ||
      'zMjH7Ng6kQLTx_EUCHhGdCUlHP8';

    cloudinary.config({
      cloud_name: cloudName,
      api_key: apiKey,
      api_secret: apiSecret,
      secure: true,
    });

    this.logger.log(`Cloudinary Service initialized for cloud: ${cloudName}`);
  }

  /**
   * Upload ảnh (hỗ trợ Base64 Data URI, URL hoặc Buffer) lên Cloudinary
   */
  async uploadImage(
    fileSource: string,
    folder: string = 'fatelink/vibes',
  ): Promise<{ url: string; publicId: string; format: string; bytes: number }> {
    try {
      const response: UploadApiResponse = await cloudinary.uploader.upload(
        fileSource,
        {
          folder,
          resource_type: 'image',
          transformation: [
            { quality: 'auto:good' },
            { fetch_format: 'auto' },
          ],
        },
      );

      return {
        url: response.secure_url,
        publicId: response.public_id,
        format: response.format,
        bytes: response.bytes,
      };
    } catch (error) {
      this.logger.error('Failed to upload image to Cloudinary', error);
      throw error;
    }
  }

  /**
   * Upload ảnh từ Buffer (Multipart file) lên Cloudinary
   */
  async uploadImageBuffer(
    buffer: Buffer,
    folder: string = 'fatelink/vibes',
    filename?: string,
  ): Promise<{ url: string; publicId: string; format: string; bytes: number }> {
    return new Promise((resolve, reject) => {
      const uploadOptions: Record<string, any> = {
        folder,
        resource_type: 'image',
        transformation: [
          { quality: 'auto:good' },
          { fetch_format: 'auto' },
        ],
      };
      if (filename) {
        uploadOptions.public_id = filename.replace(/\.[^/.]+$/, '');
      }

      const stream = cloudinary.uploader.upload_stream(
        uploadOptions,
        (error, result) => {
          if (error || !result) {
            this.logger.error('Failed to upload image buffer to Cloudinary', error);
            return reject(error || new Error('Upload image buffer failed'));
          }

          resolve({
            url: result.secure_url,
            publicId: result.public_id,
            format: result.format,
            bytes: result.bytes,
          });
        },
      );

      stream.end(buffer);
    });
  }

  /**
   * Upload tin nhắn thoại Voice Note từ Buffer (Multipart file) lên Cloudinary
   */
  async uploadAudioBuffer(
    buffer: Buffer,
    folder: string = 'fatelink/voice_notes',
    filename?: string,
  ): Promise<{ url: string; publicId: string; format: string; duration?: number; bytes: number }> {
    return new Promise((resolve, reject) => {
      const uploadOptions: Record<string, any> = {
        folder,
        resource_type: 'video', // Cloudinary quản lý âm thanh (.m4a, .mp3, .aac) trong container 'video'
      };
      if (filename) {
        uploadOptions.public_id = filename.replace(/\.[^/.]+$/, '');
      }

      const stream = cloudinary.uploader.upload_stream(
        uploadOptions,
        (error, result) => {
          if (error || !result) {
            this.logger.error('Failed to upload audio buffer to Cloudinary', error);
            return reject(error || new Error('Upload audio buffer failed'));
          }

          resolve({
            url: result.secure_url,
            publicId: result.public_id,
            format: result.format,
            duration: result.duration,
            bytes: result.bytes,
          });
        },
      );

      stream.end(buffer);
    });
  }

  /**
   * Upload tin nhắn thoại Voice Note (hỗ trợ Base64 Data URI hoặc URL) lên Cloudinary
   */
  async uploadAudio(
    fileSource: string,
    folder: string = 'fatelink/voice_notes',
  ): Promise<{ url: string; publicId: string; format: string; duration?: number; bytes: number }> {
    try {
      const response: UploadApiResponse = await cloudinary.uploader.upload(
        fileSource,
        {
          folder,
          resource_type: 'video', // Cloudinary quản lý âm thanh trong resource_type 'video'
        },
      );

      return {
        url: response.secure_url,
        publicId: response.public_id,
        format: response.format,
        duration: response.duration,
        bytes: response.bytes,
      };
    } catch (error) {
      this.logger.error('Failed to upload audio to Cloudinary', error);
      throw error;
    }
  }

  /**
   * Xóa ảnh vĩnh viễn trên Cloudinary theo publicId
   */
  async deleteImage(publicId: string): Promise<boolean> {
    try {
      const res = await cloudinary.uploader.destroy(publicId);
      return res.result === 'ok' || res.result === 'not found';
    } catch (error) {
      this.logger.error(`Failed to delete image ${publicId} from Cloudinary`, error);
      return false;
    }
  }
}

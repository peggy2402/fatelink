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

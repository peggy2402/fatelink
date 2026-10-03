import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { CloudinaryService } from '../infrastructure/services/cloudinary.service';
import { MediaController } from '../presentation/http/controllers/media.controller';

@Module({
  imports: [ConfigModule],
  controllers: [MediaController],
  providers: [CloudinaryService],
  exports: [CloudinaryService],
})
export class MediaContextModule {}

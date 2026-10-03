import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AuthSecurityModule } from '@contexts/auth/composition/auth-security.module';
import { CloudinaryService } from '../infrastructure/services/cloudinary.service';
import { MediaController } from '../presentation/http/controllers/media.controller';

@Module({
  imports: [ConfigModule, AuthSecurityModule],
  controllers: [MediaController],
  providers: [CloudinaryService],
  exports: [CloudinaryService],
})
export class MediaContextModule {}


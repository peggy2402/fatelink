import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { CompositionRootModule } from '@composition/composition-root.module';

@Module({
  imports: [CompositionRootModule],
  controllers: [AppController],
})
export class AppModule {}

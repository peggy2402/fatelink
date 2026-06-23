import { NestFactory } from '@nestjs/core';
import { RequestMethod, ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';

declare const module:
  | {
      hot?: {
        accept(): void;
        dispose(callback: () => void): void;
      };
    }
  | undefined;

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.useGlobalPipes(
    new ValidationPipe({
      transform: true,
      whitelist: true,
      forbidNonWhitelisted: false,
    }),
  );
  app.setGlobalPrefix('api', {
    exclude: [
      {
        path: '.well-known/assetlinks.json',
        method: RequestMethod.GET,
      },
      {
        path: 'tiktok/auth',
        method: RequestMethod.GET,
      },
    ],
  });
  const config = new DocumentBuilder()
    .setTitle('Fatelink API')
    .setDescription('API documentation for Fatelink')
    .setVersion('1.0')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  // Cấu hình CORS bảo mật
  app.enableCors({
    origin: [
      'http://localhost:3000',
      'https://fatelink-be.fly.dev',
      'http://10.0.2.2:3000',
    ], // Bạn có thể thêm Domain của Frontend Flutter Web vào đây
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
  });

  await app.listen(process.env.PORT ?? 3000);

  if (typeof module !== 'undefined' && module.hot) {
    module.hot.accept();
    module.hot.dispose(() => {
      void app.close();
    });
  }
}
void bootstrap();

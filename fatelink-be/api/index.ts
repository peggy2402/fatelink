import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import serverless from 'serverless-http';

let server: any;

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  await app.init();
  return serverless(app.getHttpAdapter().getInstance());
}

export default async function handler(req: any, res: any) {
  if (!server) {
    server = await bootstrap();
  }
  return server(req, res);
}
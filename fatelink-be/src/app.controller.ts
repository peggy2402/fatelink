import { Controller, Get, Header, Query, Res } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import type { Response } from 'express';
import { readFileSync } from 'fs';
import { join } from 'path';

@ApiTags('Default')
@Controller()
export class AppController {
  @Get()
  @ApiOperation({ summary: 'Kiểm tra trạng thái Server (Ping)' })
  @ApiResponse({
    status: 200,
    description: 'Trả về câu chào để xác nhận Server đang hoạt động.',
  })
  getHello(): string {
    return 'Fatelink API is running';
  }

  @Get('.well-known/assetlinks.json')
  @Header('Content-Type', 'application/json; charset=utf-8')
  getAssetLinks(): string {
    return readFileSync(
      join(process.cwd(), 'public', '.well-known', 'assetlinks.json'),
      'utf8',
    );
  }

  @Get('tiktok/auth')
  @Header('Content-Type', 'text/html; charset=utf-8')
  handleTikTokAuthCallback(
    @Query('code') code: string | undefined,
    @Query('scopes') scopes: string | undefined,
    @Query('error') error: string | undefined,
    @Query('error_description') errorDescription: string | undefined,
    @Query('errCode') errCode: string | undefined,
    @Res() res: Response,
  ) {
    const target = new URL('fatelink://tiktok/auth');
    if (code) {
      target.searchParams.set('code', code);
    }
    if (scopes) {
      target.searchParams.set('scopes', scopes);
    }
    if (error) {
      target.searchParams.set('error', error);
    }
    if (errorDescription) {
      target.searchParams.set('error_description', errorDescription);
    }
    if (errCode) {
      target.searchParams.set('errCode', errCode);
    }
    const intentTarget = `intent://tiktok/auth${target.search}#Intent;scheme=fatelink;package=com.example.fatelinkfe;end`;

    return res.send(`<!DOCTYPE html>
<html lang="vi">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>TikTok Login Redirect</title>
    <style>
      body { font-family: Arial, sans-serif; background: #111827; color: #f9fafb; display: flex; min-height: 100vh; align-items: center; justify-content: center; margin: 0; }
      .card { max-width: 420px; padding: 24px; border-radius: 16px; background: #1f2937; text-align: center; box-shadow: 0 20px 40px rgba(0,0,0,.3); }
      a { color: #60a5fa; }
      .actions { display: flex; flex-direction: column; gap: 12px; margin-top: 16px; }
      .btn { display: inline-block; padding: 12px 16px; border-radius: 10px; text-decoration: none; background: #2563eb; color: white; }
      .muted { color: #9ca3af; font-size: 14px; margin-top: 12px; }
    </style>
  </head>
  <body>
    <div class="card">
      <h1>Dang quay lai ung dung</h1>
      <p>Neu ung dung chua tu mo, bam nut ben duoi.</p>
      <div class="actions">
        <a class="btn" href="${intentTarget}">Mo FateLink tren Android</a>
        <a class="btn" href="${target.toString()}">Mo FateLink bang deep link</a>
      </div>
      <p class="muted">Neu van khong mo, hay cai lai APK debug moi va restart backend dang serve tunnel.</p>
    </div>
    <script>
      const deepLink = ${JSON.stringify(target.toString())};
      const intentLink = ${JSON.stringify(intentTarget)};
      window.location.href = intentLink;
      setTimeout(() => {
        window.location.href = deepLink;
      }, 600);
    </script>
  </body>
</html>`);
  }
}

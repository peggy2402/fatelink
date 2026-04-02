import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHello(): string {
    return 'Phạm Quỳnh Mai xinh gái - She/Her so beautiful :3 ! ♥';
  }
}

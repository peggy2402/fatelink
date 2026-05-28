import { Body, Controller, Post } from '@nestjs/common';
import { GoogleAuthTokenDto } from '../dto/google-auth-token.dto';
import { GoogleService } from './google.service';
import {
  ApiV2GoogleAuthenticate,
  ApiV2GoogleController,
} from './google.swagger';

@ApiV2GoogleController()
@Controller('auth/v2/google')
export class GoogleController {
  constructor(private readonly googleService: GoogleService) {}

  @Post()
  @ApiV2GoogleAuthenticate()
  async authenticate(@Body() body: GoogleAuthTokenDto) {
    return this.googleService.authenticate(body.token);
  }
}

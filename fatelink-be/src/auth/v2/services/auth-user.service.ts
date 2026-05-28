import { Injectable } from '@nestjs/common';
import { UserDocument } from '../../../users/schemas/user.schema';
import { UsersService } from '../../../users/users.service';
import { GoogleProfile } from '../interfaces/google-profile.interface';

@Injectable()
export class AuthUserService {
  constructor(private readonly usersService: UsersService) {}

  async authenticateWithGoogle(profile: GoogleProfile): Promise<UserDocument> {
    const userByGoogleId = await this.usersService.findByGoogleId(
      profile.googleId,
    );

    if (userByGoogleId) {
      return userByGoogleId;
    }

    const userByEmail = await this.usersService.findByEmail(profile.email);
    if (userByEmail) {
      const linkedUser = await this.usersService.linkGoogleIdentity(
        userByEmail.id,
        profile.googleId,
      );

      if (linkedUser) {
        return linkedUser;
      }
    }

    return this.usersService.createGoogleAccount(profile);
  }
}

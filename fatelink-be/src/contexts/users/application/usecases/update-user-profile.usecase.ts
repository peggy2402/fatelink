import type { UserRepository } from '@contexts/users/domain/repositories/user.repository';

export interface UpdateUserProfileInput {
  userId: string;
  name?: string;
  handle?: string;
  avatar?: string;
  bio?: string;
  gender?: string;
  dateOfBirth?: string;
  address?: string;
  isFaceLocked?: boolean;
  vibePhotos?: {
    id: string;
    imageUrl: string;
    createdAt?: Date;
    durationMinutes?: number;
    expiresAt: Date;
  }[];
}

export class UpdateUserProfileUseCase {
  constructor(private readonly userRepository: UserRepository) {}

  execute(input: UpdateUserProfileInput) {
    const { userId, ...data } = input;
    return this.userRepository.updateProfile(userId, data);
  }
}

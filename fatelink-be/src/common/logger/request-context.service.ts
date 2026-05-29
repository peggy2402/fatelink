import { Injectable } from '@nestjs/common';
import { AsyncLocalStorage } from 'async_hooks';
import { AuthenticatedRequestUser, RequestContextStore } from './log.types';

@Injectable()
export class RequestContextService {
  private readonly storage = new AsyncLocalStorage<RequestContextStore>();

  run<T>(context: RequestContextStore, callback: () => T): T {
    return this.storage.run(context, callback);
  }

  get(): RequestContextStore | undefined {
    return this.storage.getStore();
  }

  assign(values: Partial<RequestContextStore>): void {
    const store = this.storage.getStore();

    if (!store) {
      return;
    }

    Object.assign(store, values);
  }

  assignUser(user?: AuthenticatedRequestUser): void {
    if (!user) {
      return;
    }

    this.assign({
      user_id: this.resolveUserId(user),
      actor_id: this.resolveActorId(user),
    });
  }

  private resolveUserId(user: AuthenticatedRequestUser): string | undefined {
    return user.sub ?? user.userId ?? user.id;
  }

  private resolveActorId(user: AuthenticatedRequestUser): string | undefined {
    return user.actorId ?? user.sub ?? user.userId ?? user.id;
  }
}

import { Injectable, NestMiddleware } from '@nestjs/common';
import { randomBytes, randomUUID } from 'crypto';
import { NextFunction, Response } from 'express';
import { RequestContextStore, RequestWithContext } from '../logger/log.types';
import { RequestContextService } from '../logger/request-context.service';

export const REQUEST_ID_HEADER = 'X-Request-Id';
export const TRACE_ID_HEADER = 'X-Trace-Id';
export const SPAN_ID_HEADER = 'X-Span-Id';
const TRACE_PARENT_HEADER = 'traceparent';

@Injectable()
export class RequestContextMiddleware implements NestMiddleware {
  constructor(private readonly requestContext: RequestContextService) {}

  use(req: RequestWithContext, res: Response, next: NextFunction): void {
    const requestId = this.resolveRequestId(req);
    const { traceId, spanId } = this.resolveTraceContext(req);

    req.requestId = requestId;
    req.traceId = traceId;
    req.spanId = spanId;

    res.setHeader(REQUEST_ID_HEADER, requestId);
    res.setHeader(TRACE_ID_HEADER, traceId);

    if (spanId) {
      res.setHeader(SPAN_ID_HEADER, spanId);
    }

    const context: RequestContextStore = {
      request_id: requestId,
      trace_id: traceId,
      span_id: spanId,
    };

    this.requestContext.run(context, () => next());
  }

  private resolveRequestId(request: RequestWithContext): string {
    const incomingRequestId = request.header(REQUEST_ID_HEADER)?.trim();
    return incomingRequestId || randomUUID();
  }

  private resolveTraceContext(request: RequestWithContext): {
    traceId: string;
    spanId?: string;
  } {
    const explicitTraceId = request.header(TRACE_ID_HEADER)?.trim();
    const explicitSpanId = request.header(SPAN_ID_HEADER)?.trim();
    const traceParent = request.header(TRACE_PARENT_HEADER)?.trim();

    if (traceParent) {
      const parts = traceParent.split('-');
      if (parts.length === 4 && parts[1] && parts[2]) {
        return {
          traceId: parts[1],
          spanId: parts[2],
        };
      }
    }

    return {
      traceId: explicitTraceId || randomBytes(16).toString('hex'),
      spanId: explicitSpanId || randomBytes(8).toString('hex'),
    };
  }
}

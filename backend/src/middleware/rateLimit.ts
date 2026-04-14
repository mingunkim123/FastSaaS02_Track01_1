// Simple per-user in-memory rate limiter for Cloudflare Workers.
// NOTE: Cloudflare Workers may spin up multiple isolates under high traffic,
// so this provides best-effort limiting per isolate. For strict enforcement
// at scale, replace with Cloudflare Rate Limiting API or a Durable Object.

import type { Context, MiddlewareHandler, Next } from 'hono';
import type { Env } from '../db/index';
import type { Variables } from './auth';

interface RateLimitEntry {
  count: number;
  windowStart: number;
}

// Each call to createRateLimiter() returns a middleware that shares a single Map
// scoped to that middleware instance (i.e. per-route limiter).
export function createRateLimiter(
  maxRequests: number,
  windowMs: number
): MiddlewareHandler<{ Bindings: Env; Variables: Variables }> {
  const store = new Map<string, RateLimitEntry>();

  return async (
    c: Context<{ Bindings: Env; Variables: Variables }>,
    next: Next
  ): Promise<Response | void> => {
    const userId = c.get('userId');

    // If auth middleware has not yet set userId (should not happen on protected
    // routes) fall through and let the auth middleware handle it.
    if (!userId) {
      return next();
    }

    const now = Date.now();
    const entry = store.get(userId);

    if (!entry || now - entry.windowStart >= windowMs) {
      // Start a fresh window
      store.set(userId, { count: 1, windowStart: now });

      // Opportunistic cleanup: remove entries whose window has expired to avoid
      // unbounded memory growth in long-lived isolates.
      for (const [key, val] of store.entries()) {
        if (now - val.windowStart >= windowMs) {
          store.delete(key);
        }
      }
      // Re-insert after cleanup in case the user's own key was deleted above
      store.set(userId, { count: 1, windowStart: now });

      return next();
    }

    if (entry.count >= maxRequests) {
      const retryAfterSec = Math.ceil((windowMs - (now - entry.windowStart)) / 1000);
      return c.json(
        { error: 'Too many requests. Please wait before sending another message.' },
        429,
        { 'Retry-After': String(retryAfterSec) }
      );
    }

    entry.count += 1;
    return next();
  };
}

interface RateLimitEntry {
  count: number;
  resetAt: number;
}

const store = new Map<string, RateLimitEntry>();

const MAX_REQUESTS = 20;
const WINDOW_MS = 60 * 60 * 1000; // 1 hour

/**
 * IP-based rate limiting using an in-memory Map.
 * 20 requests per IP per hour.
 */
export function rateLimit(ip: string): { success: boolean; remaining: number } {
  const now = Date.now();
  const entry = store.get(ip);

  // Clean up expired entries periodically (every 100 calls)
  if (Math.random() < 0.01) {
    for (const [key, val] of store) {
      if (now > val.resetAt) store.delete(key);
    }
  }

  if (!entry || now > entry.resetAt) {
    store.set(ip, { count: 1, resetAt: now + WINDOW_MS });
    return { success: true, remaining: MAX_REQUESTS - 1 };
  }

  if (entry.count >= MAX_REQUESTS) {
    return { success: false, remaining: 0 };
  }

  entry.count += 1;
  return { success: true, remaining: MAX_REQUESTS - entry.count };
}

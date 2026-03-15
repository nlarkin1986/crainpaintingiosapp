interface RateLimitEntry {
  count: number;
  resetAt: number;
}

export interface RateLimitOptions {
  maxRequests: number;
  windowMs: number;
}

export function createRateLimit(options: RateLimitOptions) {
  const store = new Map<string, RateLimitEntry>();

  return (ip: string): { success: boolean; remaining: number } => {
    const now = Date.now();
    const entry = store.get(ip);

    // Clean up expired entries periodically.
    if (Math.random() < 0.01) {
      for (const [key, val] of store) {
        if (now > val.resetAt) store.delete(key);
      }
    }

    if (!entry || now > entry.resetAt) {
      store.set(ip, { count: 1, resetAt: now + options.windowMs });
      return { success: true, remaining: options.maxRequests - 1 };
    }

    if (entry.count >= options.maxRequests) {
      return { success: false, remaining: 0 };
    }

    entry.count += 1;
    return { success: true, remaining: options.maxRequests - entry.count };
  };
}

export const visualizationRateLimit = createRateLimit({
  maxRequests: 20,
  windowMs: 60 * 60 * 1000,
});

export const colorMatchRateLimit = createRateLimit({
  maxRequests: 30,
  windowMs: 60 * 60 * 1000,
});

export const rateLimit = visualizationRateLimit;

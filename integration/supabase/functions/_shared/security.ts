/**
 * Shared security utilities for HIKARU Security Gate.
 * Used by: execute, billing, and any Edge Function that touches Firecrawl or SyberSpider.
 *
 * - Rate limiting (per-user and per-IP)
 * - Request context extraction
 * - Payload hashing for audit
 * - Strict-Deny: all requests must be authenticated unless explicitly whitelisted
 */

/** Paths or methods that do not require authentication (Strict-Deny whitelist). */
export const WHITELISTED_METHODS = new Set<string>(["OPTIONS"]);
/** Path patterns (e.g. /health) that are allowed without auth. Empty = none. */
export const WHITELISTED_PATH_PREFIXES: string[] = ["/health"];

/**
 * Returns true if the request is whitelisted and may bypass authentication.
 * All other requests must be authenticated via the integration pipeline (Bearer token).
 */
export function isWhitelisted(req: Request): boolean {
  if (WHITELISTED_METHODS.has(req.method)) return true;
  try {
    const url = new URL(req.url);
    const path = url.pathname;
    if (WHITELISTED_PATH_PREFIXES.some((p) => path === p || path.startsWith(p + "/"))) return true;
  } catch {
    // ignore
  }
  return false;
}

export interface RequestContext {
  userId: string | null;
  ip: string;
  tier: "free" | "pro" | "enterprise";
  apiKeyId?: string;
}

/** Sliding-window rate limit state (in-memory or backed by KV/DB). */
export interface RateLimitBucket {
  key: string;
  count: number;
  windowStartMs: number;
}

/** Result of a rate limit check. */
export interface RateLimitResult {
  allowed: boolean;
  current: number;
  limit: number;
  retryAfterSeconds?: number;
}

/** Default burst threshold: 20 requests per 60 seconds. */
export const DEFAULT_BURST_THRESHOLD = 20;
export const DEFAULT_BURST_WINDOW_SECONDS = 60;

/** Credential stuffing: max failed attempts before lockout. */
export const DEFAULT_MAX_FAILED_ATTEMPTS = 5;
export const DEFAULT_LOCKOUT_MINUTES = 30;

/**
 * Extracts client IP from request (Cloudflare, Vercel, or X-Forwarded-For).
 */
export function getClientIp(req: Request): string {
  const cf = (req as Request & { cf?: { ip?: string } }).cf;
  if (cf?.ip) return cf.ip;
  const forwarded = req.headers.get("x-forwarded-for");
  if (forwarded) return forwarded.split(",")[0].trim();
  const realIp = req.headers.get("x-real-ip");
  if (realIp) return realIp;
  return "unknown";
}

/**
 * Produces a stable hash of the request body for audit (SHA-256 hex).
 * Returns empty string if body is not available or already consumed.
 */
export async function hashPayload(body: string | null): Promise<string> {
  if (body == null || body === "") return "";
  const encoder = new TextEncoder();
  const data = encoder.encode(body);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  const hashArray = new Uint8Array(hashBuffer);
  return Array.from(hashArray)
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/**
 * Simple in-memory rate limit check (sliding window).
 * For production across instances, use Redis or Postgres-backed counter.
 *
 * @param key - Unique key (e.g. `ip:${ip}` or `user:${userId}`)
 * @param limit - Max requests in the window
 * @param windowSeconds - Window length in seconds
 * @param buckets - Mutable map of key -> { count, windowStartMs }; caller must persist if needed
 */
export function checkRateLimit(
  key: string,
  limit: number,
  windowSeconds: number,
  buckets: Map<string, RateLimitBucket>
): RateLimitResult {
  const now = Date.now();
  const windowMs = windowSeconds * 1000;
  let bucket = buckets.get(key);

  if (!bucket) {
    bucket = { key, count: 1, windowStartMs: now };
    buckets.set(key, bucket);
    return { allowed: true, current: 1, limit };
  }

  if (now - bucket.windowStartMs >= windowMs) {
    bucket.count = 1;
    bucket.windowStartMs = now;
    return { allowed: true, current: 1, limit };
  }

  bucket.count += 1;
  const allowed = bucket.count <= limit;
  const retryAfterSeconds = allowed ? undefined : Math.ceil((bucket.windowStartMs + windowMs - now) / 1000);
  return {
    allowed,
    current: bucket.count,
    limit,
    retryAfterSeconds,
  };
}

/**
 * Tier daily limits for Firecrawl (API calls per day).
 */
export const TIER_DAILY_API_LIMITS: Record<RequestContext["tier"], number> = {
  free: 100,
  pro: 10_000,
  enterprise: 100_000,
};

/**
 * Tier daily limits for "commands" (e.g. SyberSpider commands).
 */
export const TIER_DAILY_COMMAND_LIMITS: Record<RequestContext["tier"], number> = {
  free: 10,
  pro: 200,
  enterprise: 1_000,
};

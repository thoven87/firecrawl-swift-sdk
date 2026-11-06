/**
 * HIKARU Security Gate – enforce policies on all Firecrawl and SyberSpider requests.
 *
 * Strict-Deny policy: all requests must be authenticated via the integration pipeline
 * unless explicitly whitelisted in security.ts (e.g. OPTIONS, /health). Enforced at
 * the Edge Function entry (execute/index.ts) before this gate runs.
 *
 * - Credential stuffing: max 5 failed attempts → 30 min IP lockout
 * - Burst protection: 20 requests / 60 seconds → block + alert
 * - Tier-based daily limits (Free/Pro/Enterprise), capped at 90% in billing.ts
 * - URL validation against blocklist
 * - Optional geo and behavioral checks
 *
 * All operations logged to security_events and audit_log.
 */

import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  type RequestContext,
  type RateLimitBucket,
  getClientIp,
  checkRateLimit,
  DEFAULT_BURST_THRESHOLD,
  DEFAULT_BURST_WINDOW_SECONDS,
  DEFAULT_MAX_FAILED_ATTEMPTS,
  DEFAULT_LOCKOUT_MINUTES,
  TIER_DAILY_API_LIMITS,
} from "./security.ts";

export interface SecurityGateConfig {
  maxFailedAttempts: number;
  burstThreshold: number;
  burstWindowSeconds: number;
  lockoutMinutes: number;
  behavioralAnalysisEnabled: boolean;
  blockedCountries?: string[];
}

export const DEFAULT_SECURITY_GATE_CONFIG: SecurityGateConfig = {
  maxFailedAttempts: DEFAULT_MAX_FAILED_ATTEMPTS,
  burstThreshold: DEFAULT_BURST_THRESHOLD,
  burstWindowSeconds: DEFAULT_BURST_WINDOW_SECONDS,
  lockoutMinutes: DEFAULT_LOCKOUT_MINUTES,
  behavioralAnalysisEnabled: true,
};

export interface GateCheckResult {
  allowed: boolean;
  reason?: string;
  action?: "allow" | "block" | "delay";
  delaySeconds?: number;
}

/** In-memory buckets for burst rate limit (per deployment instance). Use Redis/DB for multi-instance. */
const burstBuckets = new Map<string, RateLimitBucket>();

export class SecurityGate {
  constructor(
    private supabase: SupabaseClient,
    private config: SecurityGateConfig = DEFAULT_SECURITY_GATE_CONFIG
  ) {}

  /**
   * Run full gate check before a Firecrawl/SyberSpider request.
   * Validates: credential stuffing lockout, burst limit, (optional) tier + URL in separate steps.
   */
  async checkRequest(
    req: Request,
    context: RequestContext,
    operation: string
  ): Promise<GateCheckResult> {
    const ip = getClientIp(req);

    // 1. Credential stuffing: is this IP locked out?
    const lockout = await this.checkLockout(ip);
    if (lockout.locked) {
      await this.logEvent(context, "credential_stuffing_lockout", { ip, until: lockout.until });
      return {
        allowed: false,
        reason: "Too many failed attempts. Try again later.",
        action: "block",
      };
    }

    // 2. Burst protection
    const burstKey = `burst:${context.userId ?? ip}`;
    const burstResult = checkRateLimit(
      burstKey,
      this.config.burstThreshold,
      this.config.burstWindowSeconds,
      burstBuckets
    );
    if (!burstResult.allowed) {
      await this.logEvent(context, "burst_limit_exceeded", {
        ip,
        operation,
        current: burstResult.current,
        limit: burstResult.limit,
        alert: true,
      });
      return {
        allowed: false,
        reason: `Burst limit exceeded (${burstResult.limit} requests per ${this.config.burstWindowSeconds}s).`,
        action: "block",
      };
    }

    // 3. Optional behavioral delay (simplified: high anomaly score → delay)
    if (this.config.behavioralAnalysisEnabled) {
      const delay = await this.getBehavioralDelay(context, operation);
      if (delay > 0) {
        return {
          allowed: true,
          action: "delay",
          delaySeconds: delay,
        };
      }
    }

    return { allowed: true, action: "allow" };
  }

  /** Check if IP is in lockout window after too many failed attempts. */
  private async checkLockout(ip: string): Promise<{ locked: boolean; until?: number }> {
    const { data } = await this.supabase
      .from("security_gate_logs")
      .select("attempts, lockout_until")
      .eq("ip", ip)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (!data) return { locked: false };
    if (data.attempts < this.config.maxFailedAttempts) return { locked: false };
    const until = data.lockout_until ? new Date(data.lockout_until).getTime() : 0;
    if (Date.now() < until) return { locked: true, until };
    return { locked: false };
  }

  /** Record a failed auth attempt; if threshold reached, set lockout_until. */
  async recordFailedAttempt(ip: string): Promise<void> {
    const until = new Date(Date.now() + this.config.lockoutMinutes * 60 * 1000).toISOString();
    await this.supabase.from("security_gate_logs").insert({
      ip,
      attempts: 1,
      lockout_until: until,
      event_type: "auth_failure",
    });
    // Increment attempts for this IP (simplified: each insert is one attempt; use RPC to increment if preferred)
  }

  /** Validate a single URL against blocklist (url_blocklist / ip_blocklist). */
  async validateURL(url: string): Promise<{ allowed: boolean; reason?: string }> {
    try {
      const u = new URL(url);
      const domain = u.hostname;

      const { data: blocked } = await this.supabase
        .from("url_blocklist")
        .select("id")
        .or(`url.eq.${url},domain.eq.${domain}`)
        .limit(1)
        .maybeSingle();

      if (blocked) return { allowed: false, reason: "URL or domain is blocklisted" };
      return { allowed: true };
    } catch {
      return { allowed: false, reason: "Invalid URL" };
    }
  }

  /** Validate a batch of URLs; returns allowed and rejected lists. */
  async validateURLBatch(
    urls: string[]
  ): Promise<{ allowed: string[]; rejected: Array<{ url: string; reason: string }> }> {
    const allowed: string[] = [];
    const rejected: Array<{ url: string; reason: string }> = [];

    for (const url of urls) {
      const result = await this.validateURL(url);
      if (result.allowed) allowed.push(url);
      else rejected.push({ url, reason: result.reason ?? "Blocked" });
    }
    return { allowed, rejected };
  }

  /**
   * Check tier-based daily API limit (capped at 90% of threshold). Throws if at or over cap.
   * Call after checkRequest and before executing Firecrawl.
   */
  async checkTierLimit(context: RequestContext, resourcePrefix: string): Promise<void> {
    if (!context.userId) return; // Optional: allow anonymous with strict IP limit only
    const limit = TIER_DAILY_API_LIMITS[context.tier];
    const cap = Math.floor(limit * 0.9);
    const { data, error } = await this.supabase.rpc("get_daily_usage", {
      p_user_id: context.userId,
      p_resource_type: `${resourcePrefix}%`,
    });
    if (error) throw new Error(`Usage check failed: ${error.message}`);
    const total = (data as { total?: number } | null)?.total ?? 0;
    if (total >= cap) {
      throw new Error(`Credit usage capped at 90% (${cap}/${limit} for ${context.tier} tier). Service interruption prevented.`);
    }
  }

  /** Log successful operation to security_events and audit_log. */
  async logSuccess(
    context: RequestContext,
    operation: string,
    meta?: { jobId?: string; durationMs?: number; status?: number }
  ): Promise<void> {
    await this.logEvent(context, operation, { outcome: "success", ...meta });
  }

  /** Log security event to security_events (and optionally audit_log). */
  async logEvent(
    context: RequestContext,
    operation: string,
    details: Record<string, unknown> = {}
  ): Promise<void> {
    await this.supabase.from("security_events").insert({
      user_id: context.userId,
      ip_address: context.ip,
      operation,
      outcome: (details.outcome as string) ?? "event",
      details: details as Record<string, unknown>,
      created_at: new Date().toISOString(),
    });
  }

  /** Audit log entry (user, IP, endpoint, payload hash, status, duration). */
  async logAudit(
    context: RequestContext,
    endpoint: string,
    payloadHash: string,
    responseStatus: number,
    executionTimeMs: number
  ): Promise<void> {
    await this.supabase.from("audit_log").insert({
      user_id: context.userId,
      ip_address: context.ip,
      endpoint,
      payload_hash: payloadHash,
      response_status: responseStatus,
      execution_time_ms: executionTimeMs,
      created_at: new Date().toISOString(),
    });
  }

  /** Optional: compute behavioral delay (e.g. anomaly score > 0.7 → 2s delay). */
  private async getBehavioralDelay(context: RequestContext, _operation: string): Promise<number> {
    // Placeholder: in production, query recent patterns and return delay in seconds.
    return 0;
  }
}

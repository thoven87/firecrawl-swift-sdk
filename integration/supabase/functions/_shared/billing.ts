/**
 * Usage tracking and tier limits for Firecrawl operations.
 * Integrates with usage_tracking, usage_daily_aggregates, and Stripe-backed tiers.
 * Credit usage is capped at 90% of tier threshold to prevent service interruption or overages.
 *
 * @see docs/SECURITY_GATE.md (rate limit per user tier)
 * @see AUDIT_STATUS_AND_MONETIZATION.md (tier limits)
 */

import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { TIER_DAILY_API_LIMITS } from "./security.ts";

/** Cap usage at 90% of tier limit to avoid overages and service interruption. */
export const USAGE_CAP_RATIO = 0.9;

export type FirecrawlOperation = "scrape" | "crawl" | "agent" | "map" | "batch_scrape";

export type SubscriptionTier = "free" | "pro" | "enterprise";

export const TIER_LIMITS: Record<
  SubscriptionTier,
  { firecrawl: number; commands: number }
> = {
  free: { firecrawl: 100, commands: 10 },
  pro: { firecrawl: 10_000, commands: 200 },
  enterprise: { firecrawl: 100_000, commands: 1_000 },
};

/**
 * Record a Firecrawl operation in usage_tracking and enforce daily tier limit.
 * Call this after a successful Firecrawl call.
 *
 * @throws Error if daily limit for the user's tier would be exceeded
 */
export async function trackFirecrawlUsage(
  supabase: SupabaseClient,
  userId: string,
  operation: FirecrawlOperation,
  quantity: number = 1
): Promise<void> {
  const resourceType = `firecrawl_${operation}`;

  const { error: insertError } = await supabase.from("usage_tracking").insert({
    user_id: userId,
    resource_type: resourceType,
    resource_id: crypto.randomUUID(),
    quantity,
    created_at: new Date().toISOString(),
  });

  if (insertError) throw new Error(`Usage tracking failed: ${insertError.message}`);

  const tier = await getUserTier(supabase, userId);
  const limit = TIER_LIMITS[tier].firecrawl;
  const cap = Math.floor(limit * USAGE_CAP_RATIO);

  const { data, error } = await supabase.rpc("get_daily_usage", {
    p_user_id: userId,
    p_resource_type: "firecrawl_%",
  });

  if (error) throw new Error(`Daily usage check failed: ${error.message}`);

  const total = (data as { total?: number } | null)?.total ?? 0;
  if (total >= cap) {
    throw new Error(
      `Credit usage capped at 90% of threshold (${cap}/${limit} for ${tier} tier). Used: ${total}. Service interruption prevented.`
    );
  }
}

/**
 * Get the user's subscription tier (from user_profiles or subscription_plans).
 */
export async function getUserTier(
  supabase: SupabaseClient,
  userId: string
): Promise<SubscriptionTier> {
  const { data, error } = await supabase
    .from("user_profiles")
    .select("subscription_tier")
    .eq("id", userId)
    .maybeSingle();

  if (error || !data) return "free";
  const tier = (data.subscription_tier as string)?.toLowerCase();
  if (tier === "pro" || tier === "enterprise") return tier as SubscriptionTier;
  return "free";
}

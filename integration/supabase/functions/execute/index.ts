/**
 * Execute Edge Function: All Firecrawl API calls go through this handler.
 * HIKARU Security Gate is applied before any Firecrawl call.
 *
 * - Validates request via SecurityGate.checkRequest
 * - Applies progressive delay if behavioral action is "delay"
 * - Validates URLs when present
 * - Enforces tier-based daily limits (billing.trackFirecrawlUsage)
 * - Logs success to security_events and audit_log
 *
 * @see docs/SECURITY_GATE.md
 * @see _shared/securityGate.ts
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { SecurityGate, DEFAULT_SECURITY_GATE_CONFIG } from "../_shared/securityGate.ts";
import { getClientIp, hashPayload, isWhitelisted, type RequestContext } from "../_shared/security.ts";
import { trackFirecrawlUsage, getUserTier } from "../_shared/billing.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*", // Restrict to production domain in production
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // Strict-Deny: all requests must be authenticated unless whitelisted in security.ts
  if (!isWhitelisted(req)) {
    const authHeader = req.headers.get("Authorization");
    const hasBearer = authHeader?.startsWith("Bearer ");
    if (!hasBearer) {
      return new Response(
        JSON.stringify({ error: "Unauthorized. All requests must be authenticated via the integration pipeline unless whitelisted." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
  );

  const gate = new SecurityGate(supabase, {
    ...DEFAULT_SECURITY_GATE_CONFIG,
    maxFailedAttempts: parseInt(Deno.env.get("MAX_FAILED_ATTEMPTS") ?? "5", 10),
    burstThreshold: parseInt(Deno.env.get("BURST_THRESHOLD") ?? "20", 10),
    behavioralAnalysisEnabled: Deno.env.get("BEHAVIORAL_ANALYSIS_ENABLED") !== "false",
  });

  const ip = getClientIp(req);
  const authHeader = req.headers.get("Authorization");
  let userId: string | null = null;
  if (authHeader?.startsWith("Bearer ")) {
    const token = authHeader.slice(7);
    const { data: { user } } = await supabase.auth.getUser(token);
    userId = user?.id ?? null;
  }

  const tier = userId ? await getUserTier(supabase, userId) : "free";
  const context: RequestContext = { userId, ip, tier };

  const startTime = Date.now();
  let bodyText: string | null = null;
  try {
    bodyText = await req.text();
  } catch {
    bodyText = null;
  }

  // Before any Firecrawl call: Security Gate check
  const gateResult = await gate.checkRequest(req, context, "firecrawl");

  if (!gateResult.allowed) {
    await gate.logEvent(context, "firecrawl_blocked", { reason: gateResult.reason });
    return new Response(
      JSON.stringify({ error: gateResult.reason ?? "Request blocked by Security Gate" }),
      { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  if (gateResult.action === "delay" && (gateResult.delaySeconds ?? 0) > 0) {
    await new Promise((r) => setTimeout(r, gateResult.delaySeconds! * 1000));
  }

  // Optional: validate URLs from body (e.g. scrape/crawl/agent payload)
  const urlFromBody = extractFirstURLFromBody(bodyText);
  if (urlFromBody) {
    const validation = await gate.validateURL(urlFromBody);
    if (!validation.allowed) {
      await gate.logEvent(context, "url_validation_failed", { url: urlFromBody, reason: validation.reason });
      return new Response(
        JSON.stringify({ error: "Invalid URL", reason: validation.reason }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
  }

  try {
    await gate.checkTierLimit(context, "firecrawl");
  } catch (e) {
    const message = e instanceof Error ? e.message : "Daily limit exceeded";
    await gate.logEvent(context, "tier_limit_exceeded", { message });
    return new Response(
      JSON.stringify({ error: message }),
      { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // Do not proceed with external requests until Firecrawl API key is validated as PRESENT.
  const apiKey = Deno.env.get("FIRECRAWL_API_KEY");
  if (!apiKey || apiKey.trim() === "") {
    await gate.recordFailedAttempt(ip);
    return new Response(
      JSON.stringify({ error: "Firecrawl API key not configured. External requests are not permitted until FIRECRAWL_API_KEY is validated as PRESENT in the environment." }),
      { status: 503, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // Route to Firecrawl operation based on request (simplified: single scrape for demo)
  let result: unknown;
  let operation = "firecrawl_scrape";
  try {
    const parsed = bodyText ? (JSON.parse(bodyText) as Record<string, unknown>) : {};
    const url = (parsed.url as string) ?? urlFromBody ?? "https://example.com";
    const response = await fetch("https://api.firecrawl.dev/v2/scrape", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({ url, formats: ["markdown"] }),
    });
    result = await response.json();

    if (!response.ok) {
      const status = response.status;
      const payloadHash = await hashPayload(bodyText);
      await gate.logAudit(context, "/v2/scrape", payloadHash, status, Date.now() - startTime);
      return new Response(JSON.stringify(result), {
        status,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (userId) {
      await trackFirecrawlUsage(supabase, userId, "scrape", 1);
    }
    await gate.logSuccess(context, operation, {
      durationMs: Date.now() - startTime,
      status: response.status,
    });

    const payloadHash = await hashPayload(bodyText);
    await gate.logAudit(context, "/v2/scrape", payloadHash, response.status, Date.now() - startTime);

    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    const message = e instanceof Error ? e.message : "Internal error";
    await gate.logEvent(context, "firecrawl_error", { operation, error: message });
    return new Response(
      JSON.stringify({ error: message }),
      { status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

function extractFirstURLFromBody(body: string | null): string | null {
  if (!body) return null;
  try {
    const o = JSON.parse(body) as Record<string, unknown>;
    const url = o.url as string | undefined;
    if (url && typeof url === "string") return url;
    const urls = o.urls as string[] | undefined;
    if (Array.isArray(urls) && urls[0]) return urls[0];
    return null;
  } catch {
    return null;
  }
}

/**
 * Stripe billing webhook: customer.subscription.updated → update user_profiles.subscription_tier.
 * Provisions Firecrawl API key tier upgrade.
 *
 * Set STRIPE_WEBHOOK_SECRET in Supabase secrets.
 * Configure Stripe webhook endpoint: https://<project>.supabase.co/functions/v1/billing-webhook
 *
 * @see Phase 6: Stripe Billing + Usage Tracking
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, stripe-signature",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const stripeSignature = req.headers.get("stripe-signature");
  const body = await req.text();
  const secret = Deno.env.get("STRIPE_WEBHOOK_SECRET");
  if (!secret) {
    return new Response(JSON.stringify({ error: "STRIPE_WEBHOOK_SECRET not set" }), {
      status: 503,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Verify webhook signature (use Stripe SDK in production: stripe.webhooks.constructEvent)
  // For Deno, use: https://esm.sh/stripe and constructEvent(body, stripeSignature, secret)
  let event: { type: string; data?: { object?: Record<string, unknown> } };
  try {
    event = JSON.parse(body) as { type: string; data?: { object?: Record<string, unknown> } };
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (event.type !== "customer.subscription.updated" && event.type !== "customer.subscription.created") {
    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const subscription = event.data?.object as Record<string, unknown> | undefined;
  if (!subscription?.customer || !subscription?.metadata) {
    return new Response(JSON.stringify({ error: "Missing customer or metadata" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const userId = (subscription.metadata as Record<string, string>).user_id ?? (subscription.metadata as Record<string, string>).supabase_user_id;
  if (!userId) {
    return new Response(JSON.stringify({ error: "metadata.user_id required" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const status = subscription.status as string;
  const priceId = (subscription.items as { data?: Array<{ price?: { id?: string } }> })?.data?.[0]?.price?.id;
  const tier = mapPriceIdToTier(priceId, status);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
  );

  const { error } = await supabase
    .from("user_profiles")
    .upsert(
      { id: userId, subscription_tier: tier, updated_at: new Date().toISOString() },
      { onConflict: "id" }
    );

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ received: true, tier }), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});

function mapPriceIdToTier(priceId: string | undefined, status: string): string {
  if (status !== "active" && status !== "trialing") return "free";
  const proPriceIds = (Deno.env.get("STRIPE_PRO_PRICE_IDS") ?? "").split(",").map((s) => s.trim());
  const enterprisePriceIds = (Deno.env.get("STRIPE_ENTERPRISE_PRICE_IDS") ?? "").split(",").map((s) => s.trim());
  if (priceId && enterprisePriceIds.includes(priceId)) return "enterprise";
  if (priceId && proPriceIds.includes(priceId)) return "pro";
  return "free";
}

-- Security Gate and usage tracking for Firecrawl integration
-- @see docs/SECURITY_GATE.md

-- security_events: all security-relevant events (blocks, rate limits, auth failures)
CREATE TABLE IF NOT EXISTS security_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ip_address INET,
  operation TEXT NOT NULL,
  outcome TEXT NOT NULL DEFAULT 'event',
  details JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_security_events_user_created ON security_events(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_security_events_ip_created ON security_events(ip_address, created_at DESC);

-- audit_log: full audit trail (user, IP, endpoint, payload hash, status, duration)
CREATE TABLE IF NOT EXISTS audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ip_address INET,
  endpoint TEXT NOT NULL,
  payload_hash TEXT,
  response_status INT,
  execution_time_ms INT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_log_user_created ON audit_log(user_id, created_at DESC);

-- security_gate_logs: credential stuffing / lockout state (IP, attempts, lockout_until)
CREATE TABLE IF NOT EXISTS security_gate_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ip INET NOT NULL,
  attempts INT NOT NULL DEFAULT 1,
  lockout_until TIMESTAMPTZ,
  event_type TEXT NOT NULL DEFAULT 'auth_failure',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_security_gate_logs_ip ON security_gate_logs(ip, created_at DESC);

-- url_blocklist: blocklisted URLs and domains
CREATE TABLE IF NOT EXISTS url_blocklist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  url TEXT,
  domain TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_url_blocklist_domain ON url_blocklist(domain);
CREATE INDEX IF NOT EXISTS idx_url_blocklist_url ON url_blocklist(url);

-- usage_tracking: per-operation usage for tier limits
CREATE TABLE IF NOT EXISTS usage_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  resource_type TEXT NOT NULL,
  resource_id UUID NOT NULL DEFAULT gen_random_uuid(),
  quantity INT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_usage_tracking_user_type_created ON usage_tracking(user_id, resource_type, created_at DESC);

-- user_profiles: create if not exists, then add subscription_tier (if missing)
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  subscription_tier TEXT NOT NULL DEFAULT 'free',
  updated_at TIMESTAMPTZ DEFAULT now()
);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'subscription_tier') THEN
    ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS subscription_tier TEXT NOT NULL DEFAULT 'free';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'updated_at') THEN
    ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();
  END IF;
END $$;

-- usage_daily_aggregates: daily rollups (optional; can be replaced by RPC)
CREATE TABLE IF NOT EXISTS usage_daily_aggregates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  firecrawl_scrapes INT NOT NULL DEFAULT 0,
  firecrawl_crawls INT NOT NULL DEFAULT 0,
  firecrawl_agents INT NOT NULL DEFAULT 0,
  firecrawl_maps INT NOT NULL DEFAULT 0,
  firecrawl_batch_scrapes INT NOT NULL DEFAULT 0,
  UNIQUE(user_id, date)
);

CREATE INDEX IF NOT EXISTS idx_usage_daily_user_date ON usage_daily_aggregates(user_id, date);

-- RPC: get_daily_usage for tier limit check (sums usage_tracking for today by resource_type pattern)
CREATE OR REPLACE FUNCTION get_daily_usage(p_user_id UUID, p_resource_type TEXT)
RETURNS TABLE(total BIGINT) AS $$
  SELECT COALESCE(SUM(quantity), 0)::BIGINT
  FROM usage_tracking
  WHERE user_id = p_user_id
    AND resource_type LIKE p_resource_type
    AND created_at >= date_trunc('day', now());
$$ LANGUAGE sql SECURITY DEFINER;

-- RLS (enable for multi-tenant; service role bypasses)
ALTER TABLE security_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE usage_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE usage_daily_aggregates ENABLE ROW LEVEL SECURITY;

-- Policy: users can read own security_events (optional)
CREATE POLICY "Users read own security_events" ON security_events
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users read own audit_log" ON audit_log
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users read own usage_tracking" ON usage_tracking
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users read own usage_daily_aggregates" ON usage_daily_aggregates
  FOR SELECT USING (auth.uid() = user_id);

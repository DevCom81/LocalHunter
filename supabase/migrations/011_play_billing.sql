-- Migration 011 : suivi des abonnements Google Play Billing.
-- Le tier profiles.subscription_tier est mis à jour uniquement via Edge Functions
-- (service role) après vérification auprès de l'API Google Play.

CREATE TABLE play_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL,
  purchase_token TEXT NOT NULL UNIQUE,
  subscription_tier TEXT NOT NULL
    CHECK (subscription_tier IN ('premium', 'premium_plus', 'pro')),
  subscription_state TEXT NOT NULL,
  expiry_time TIMESTAMPTZ,
  auto_renewing BOOLEAN,
  obfuscated_account_id TEXT,
  raw_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX play_subscriptions_user_id_idx ON play_subscriptions(user_id);

ALTER TABLE play_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY play_subscriptions_select_own ON play_subscriptions
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

REVOKE INSERT, UPDATE, DELETE ON play_subscriptions FROM authenticated, anon;

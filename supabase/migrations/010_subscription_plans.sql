-- Migration 010 : 4 paliers d'abonnement avec quotas par tier.
-- freemium (inchangé) | premium | premium_plus | pro
-- Quota IA mensuel suivi dans ai_generation_usage (Edge Function).

ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_subscription_tier_check;

ALTER TABLE profiles
  ADD CONSTRAINT profiles_subscription_tier_check
  CHECK (subscription_tier IN ('freemium', 'premium', 'premium_plus', 'pro'));

CREATE TABLE IF NOT EXISTS ai_generation_usage (
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  period_month DATE NOT NULL,
  used_count INT NOT NULL DEFAULT 0 CHECK (used_count >= 0),
  PRIMARY KEY (user_id, period_month)
);

ALTER TABLE ai_generation_usage ENABLE ROW LEVEL SECURITY;

-- Accès réservé au service role (Edge Function).
REVOKE ALL ON ai_generation_usage FROM authenticated, anon;

CREATE OR REPLACE FUNCTION subscription_limits(uid UUID)
RETURNS TABLE (
  max_campaigns INT,
  max_grids INT,
  max_ai_generations INT,
  max_prospects_per_campaign INT
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT
    CASE p.subscription_tier
      WHEN 'freemium' THEN 1
      WHEN 'premium' THEN 5
      WHEN 'premium_plus' THEN 10
      ELSE NULL
    END,
    CASE p.subscription_tier
      WHEN 'freemium' THEN 1
      WHEN 'premium' THEN 2
      WHEN 'premium_plus' THEN 5
      ELSE NULL
    END,
    CASE p.subscription_tier
      WHEN 'premium' THEN 2
      WHEN 'premium_plus' THEN 5
      ELSE NULL
    END,
    CASE p.subscription_tier
      WHEN 'freemium' THEN 5
      WHEN 'premium' THEN 20
      WHEN 'premium_plus' THEN 50
      ELSE NULL
    END
  FROM profiles p
  WHERE p.id = uid;
$$;

CREATE OR REPLACE FUNCTION enforce_tier_campaign_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  lim RECORD;
  current_count INT;
BEGIN
  SELECT * INTO lim FROM subscription_limits(NEW.user_id);
  IF lim.max_campaigns IS NULL THEN
    RETURN NEW;
  END IF;
  SELECT count(*) INTO current_count FROM campaigns WHERE user_id = NEW.user_id;
  IF current_count >= lim.max_campaigns THEN
    RAISE EXCEPTION 'TIER_LIMIT: quota campagnes atteint pour votre offre';
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION enforce_tier_grid_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  lim RECORD;
  current_count INT;
BEGIN
  SELECT * INTO lim FROM subscription_limits(NEW.user_id);
  IF lim.max_grids IS NULL THEN
    RETURN NEW;
  END IF;
  SELECT count(*) INTO current_count
    FROM scoring_grids WHERE user_id = NEW.user_id;
  IF current_count >= lim.max_grids THEN
    RAISE EXCEPTION 'TIER_LIMIT: quota grilles de scoring atteint pour votre offre';
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION enforce_tier_prospect_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  owner UUID;
  lim RECORD;
  current_count INT;
BEGIN
  SELECT c.user_id INTO owner FROM campaigns c WHERE c.id = NEW.campaign_id;
  IF owner IS NULL THEN
    RETURN NEW;
  END IF;
  SELECT * INTO lim FROM subscription_limits(owner);
  IF lim.max_prospects_per_campaign IS NULL THEN
    RETURN NEW;
  END IF;
  SELECT count(*) INTO current_count
    FROM prospects WHERE campaign_id = NEW.campaign_id;
  IF current_count >= lim.max_prospects_per_campaign THEN
    RAISE EXCEPTION 'TIER_LIMIT: quota prospects par campagne atteint pour votre offre';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS campaigns_freemium_limit ON campaigns;
DROP TRIGGER IF EXISTS scoring_grids_freemium_limit ON scoring_grids;
DROP TRIGGER IF EXISTS prospects_freemium_limit ON prospects;

CREATE TRIGGER campaigns_tier_limit
  BEFORE INSERT ON campaigns
  FOR EACH ROW EXECUTE FUNCTION enforce_tier_campaign_limit();

CREATE TRIGGER scoring_grids_tier_limit
  BEFORE INSERT ON scoring_grids
  FOR EACH ROW EXECUTE FUNCTION enforce_tier_grid_limit();

CREATE TRIGGER prospects_tier_limit
  BEFORE INSERT ON prospects
  FOR EACH ROW EXECUTE FUNCTION enforce_tier_prospect_limit();

DROP FUNCTION IF EXISTS is_premium(UUID);

DROP FUNCTION IF EXISTS enforce_freemium_campaign_limit();
DROP FUNCTION IF EXISTS enforce_freemium_grid_limit();
DROP FUNCTION IF EXISTS enforce_freemium_prospect_limit();

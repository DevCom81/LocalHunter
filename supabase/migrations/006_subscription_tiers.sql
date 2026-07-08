-- Migration 006: niveaux d'abonnement (freemium / premium).
-- Défaut : freemium. Changement de niveau UNIQUEMENT manuel (Dashboard /
-- service role) en attendant la monétisation Google Play.
-- Quotas freemium appliqués en base (non contournables par un client modifié) :
--   1 campagne, 1 grille de scoring personnelle, 5 prospects par campagne.

ALTER TABLE profiles
  ADD COLUMN subscription_tier TEXT NOT NULL DEFAULT 'freemium'
  CHECK (subscription_tier IN ('freemium', 'premium'));

-- L'utilisateur peut modifier son profil (email, nom) mais jamais son tier :
-- on remplace le droit UPDATE global par un droit limité aux colonnes sûres.
REVOKE UPDATE ON profiles FROM authenticated;
GRANT UPDATE (email, full_name) ON profiles TO authenticated;

CREATE OR REPLACE FUNCTION is_premium(uid UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT COALESCE(
    (SELECT subscription_tier = 'premium' FROM profiles WHERE id = uid),
    false
  );
$$;

CREATE OR REPLACE FUNCTION enforce_freemium_campaign_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_premium(NEW.user_id)
     AND (SELECT count(*) FROM campaigns WHERE user_id = NEW.user_id) >= 1 THEN
    RAISE EXCEPTION 'FREEMIUM_LIMIT: offre gratuite limitée à 1 campagne';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER campaigns_freemium_limit
  BEFORE INSERT ON campaigns
  FOR EACH ROW EXECUTE FUNCTION enforce_freemium_campaign_limit();

CREATE OR REPLACE FUNCTION enforce_freemium_grid_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_premium(NEW.user_id)
     AND (SELECT count(*) FROM scoring_grids WHERE user_id = NEW.user_id) >= 1 THEN
    RAISE EXCEPTION 'FREEMIUM_LIMIT: offre gratuite limitée à 1 grille de scoring';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER scoring_grids_freemium_limit
  BEFORE INSERT ON scoring_grids
  FOR EACH ROW EXECUTE FUNCTION enforce_freemium_grid_limit();

CREATE OR REPLACE FUNCTION enforce_freemium_prospect_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  owner UUID;
BEGIN
  SELECT c.user_id INTO owner FROM campaigns c WHERE c.id = NEW.campaign_id;
  IF owner IS NOT NULL AND NOT is_premium(owner)
     AND (SELECT count(*) FROM prospects WHERE campaign_id = NEW.campaign_id) >= 5 THEN
    RAISE EXCEPTION 'FREEMIUM_LIMIT: offre gratuite limitée à 5 prospects par campagne';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER prospects_freemium_limit
  BEFORE INSERT ON prospects
  FOR EACH ROW EXECUTE FUNCTION enforce_freemium_prospect_limit();

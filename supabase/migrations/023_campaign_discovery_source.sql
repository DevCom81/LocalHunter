-- Phase 9 : source de découverte campagne (Places défaut = rétrocompat).
-- BODACC reste enrichissement manuel / différé, pas une source de discovery.
-- Forme idempotente (évite échec silencieux ADD COLUMN + CHECK combinés).

ALTER TABLE campaigns
  ADD COLUMN IF NOT EXISTS discovery_source TEXT;

UPDATE campaigns
SET discovery_source = 'places'
WHERE discovery_source IS NULL;

ALTER TABLE campaigns
  ALTER COLUMN discovery_source SET DEFAULT 'places';

ALTER TABLE campaigns
  ALTER COLUMN discovery_source SET NOT NULL;

DO $$
BEGIN
  ALTER TABLE campaigns
    ADD CONSTRAINT campaigns_discovery_source_check
    CHECK (discovery_source IN ('places', 'sirene'));
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

COMMENT ON COLUMN campaigns.discovery_source IS
  'Source de découverte : places (Google) ou sirene (registre). '
  'BODACC = enrichissement séparé (manuel ou différé).';

-- Recharge le cache PostgREST (sinon INSERT → 400 PGRST204).
NOTIFY pgrst, 'reload schema';

-- Phase 12 : discovery composite Places + SIRENE.
-- Rétrocompat : places / sirene conservés ; combined = défaut nouvelles campagnes.

ALTER TABLE campaigns DROP CONSTRAINT IF EXISTS campaigns_discovery_source_check;

ALTER TABLE campaigns
  ADD CONSTRAINT campaigns_discovery_source_check
  CHECK (discovery_source IN ('places', 'sirene', 'combined'));

ALTER TABLE campaigns
  ALTER COLUMN discovery_source SET DEFAULT 'combined';

COMMENT ON COLUMN campaigns.discovery_source IS
  'Source de découverte : combined (Places+SIRENE, défaut), places, ou sirene. '
  'BODACC = enrichissement séparé.';

NOTIFY pgrst, 'reload schema';

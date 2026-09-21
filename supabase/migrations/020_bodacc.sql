-- Migration 020 : BODACC (option C4.1).
-- Signaux normalisés sur prospects + événements normalisés.
-- Brut / quasi-brut : enrichment_cache (clé bodacc_v1:{siren}, TTL 30j).

ALTER TABLE prospects
  ADD COLUMN IF NOT EXISTS bodacc_fetched_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS bodacc_last_event_at DATE,
  ADD COLUMN IF NOT EXISTS bodacc_no_results BOOLEAN,
  ADD COLUMN IF NOT EXISTS bodacc_has_creation BOOLEAN,
  ADD COLUMN IF NOT EXISTS bodacc_has_accounts_filing BOOLEAN,
  ADD COLUMN IF NOT EXISTS bodacc_has_modification BOOLEAN,
  ADD COLUMN IF NOT EXISTS bodacc_has_sale BOOLEAN,
  ADD COLUMN IF NOT EXISTS bodacc_has_radiation BOOLEAN,
  ADD COLUMN IF NOT EXISTS bodacc_has_liquidation BOOLEAN,
  ADD COLUMN IF NOT EXISTS bodacc_has_collective_proceeding BOOLEAN,
  ADD COLUMN IF NOT EXISTS bodacc_has_manager_change BOOLEAN,
  ADD COLUMN IF NOT EXISTS bodacc_has_address_change BOOLEAN,
  ADD COLUMN IF NOT EXISTS bodacc_signal_confidence TEXT
    CHECK (
      bodacc_signal_confidence IS NULL
      OR bodacc_signal_confidence IN ('low', 'medium', 'high')
    ),
  ADD COLUMN IF NOT EXISTS bodacc_radiation_status TEXT
    CHECK (
      bodacc_radiation_status IS NULL
      OR bodacc_radiation_status IN ('none', 'excluded', 'review')
    );

CREATE TABLE IF NOT EXISTS bodacc_events (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prospect_id     UUID NOT NULL REFERENCES prospects(id) ON DELETE CASCADE,
  siren           TEXT NOT NULL,
  bodacc_id       TEXT NOT NULL,
  date_parution   DATE,
  famille         TEXT,
  type_avis       TEXT,
  signal_key      TEXT NOT NULL,
  ville           TEXT,
  url             TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (prospect_id, bodacc_id)
);

CREATE INDEX IF NOT EXISTS idx_bodacc_events_prospect
  ON bodacc_events (prospect_id);

CREATE INDEX IF NOT EXISTS idx_bodacc_events_siren
  ON bodacc_events (siren);

ALTER TABLE bodacc_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY bodacc_events_owner ON bodacc_events
  FOR ALL TO authenticated
  USING (
    prospect_id IN (
      SELECT p.id FROM prospects p
      JOIN campaigns c ON c.id = p.campaign_id
      WHERE c.user_id = auth.uid()
    )
  )
  WITH CHECK (
    prospect_id IN (
      SELECT p.id FROM prospects p
      JOIN campaigns c ON c.id = p.campaign_id
      WHERE c.user_id = auth.uid()
    )
  );

-- Source métrique bodacc (C1 étendu).
ALTER TABLE edge_metrics_daily
  DROP CONSTRAINT IF EXISTS edge_metrics_daily_source_check;

ALTER TABLE edge_metrics_daily
  ADD CONSTRAINT edge_metrics_daily_source_check
  CHECK (source IN (
    'places', 'sirene', 'pagespeed', 'company', 'grid_gen',
    'enrichment', 'website', 'bodacc'
  ));

-- Migration 019 : analyse légère de site web (option C3).
-- Colonnes additives ; source métrique 'website'.

ALTER TABLE prospects
  ADD COLUMN IF NOT EXISTS website_reachable BOOLEAN,
  ADD COLUMN IF NOT EXISTS website_https BOOLEAN,
  ADD COLUMN IF NOT EXISTS website_http_status INT
    CHECK (
      website_http_status IS NULL
      OR (website_http_status >= 100 AND website_http_status < 600)
    ),
  ADD COLUMN IF NOT EXISTS website_title TEXT,
  ADD COLUMN IF NOT EXISTS website_has_viewport BOOLEAN;

-- Étend le CHECK source des métriques Edge (017).
ALTER TABLE edge_metrics_daily
  DROP CONSTRAINT IF EXISTS edge_metrics_daily_source_check;

ALTER TABLE edge_metrics_daily
  ADD CONSTRAINT edge_metrics_daily_source_check
  CHECK (source IN (
    'places', 'sirene', 'pagespeed', 'company', 'grid_gen', 'enrichment', 'website'
  ));

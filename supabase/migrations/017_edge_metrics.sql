-- Migration 017 : métriques Edge agrégées (option C1).
-- Labels basse cardinalité uniquement : source, status, error_type.
-- Aucune PII (pas d'email, SIREN, URL, user_id).

CREATE TABLE IF NOT EXISTS edge_metrics_daily (
  metric_day         DATE NOT NULL DEFAULT CURRENT_DATE,
  source             TEXT NOT NULL
    CHECK (source IN (
      'places', 'sirene', 'pagespeed', 'company', 'grid_gen', 'enrichment'
    )),
  status             TEXT NOT NULL
    CHECK (status IN ('success', 'failure', 'cache_hit', 'skip')),
  error_type         TEXT NOT NULL DEFAULT '',
  event_count        INT NOT NULL DEFAULT 0 CHECK (event_count >= 0),
  total_duration_ms  BIGINT NOT NULL DEFAULT 0 CHECK (total_duration_ms >= 0),
  PRIMARY KEY (metric_day, source, status, error_type)
);

ALTER TABLE edge_metrics_daily ENABLE ROW LEVEL SECURITY;

-- Accès réservé au service role (Edge Functions).
REVOKE ALL ON edge_metrics_daily FROM authenticated, anon;

CREATE OR REPLACE FUNCTION increment_edge_metric(
  p_source TEXT,
  p_status TEXT,
  p_error_type TEXT DEFAULT '',
  p_duration_ms INT DEFAULT 0,
  p_count INT DEFAULT 1
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INT := GREATEST(COALESCE(p_count, 1), 1);
  v_duration BIGINT := GREATEST(COALESCE(p_duration_ms, 0), 0) * v_count;
  v_error TEXT := COALESCE(p_error_type, '');
BEGIN
  INSERT INTO edge_metrics_daily (
    metric_day, source, status, error_type, event_count, total_duration_ms
  ) VALUES (
    CURRENT_DATE, p_source, p_status, v_error, v_count, v_duration
  )
  ON CONFLICT (metric_day, source, status, error_type)
  DO UPDATE SET
    event_count = edge_metrics_daily.event_count + EXCLUDED.event_count,
    total_duration_ms =
      edge_metrics_daily.total_duration_ms + EXCLUDED.total_duration_ms;
END;
$$;

REVOKE ALL ON FUNCTION increment_edge_metric(TEXT, TEXT, TEXT, INT, INT)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION increment_edge_metric(TEXT, TEXT, TEXT, INT, INT)
  TO service_role;

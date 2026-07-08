-- Migration 008 : enrichissement prospects (SIRENE + PageSpeed).

-- 1) Nouvelles données portées par le prospect
ALTER TABLE prospects
  ADD COLUMN IF NOT EXISTS creation_date DATE,
  ADD COLUMN IF NOT EXISTS pagespeed_score INT
    CHECK (pagespeed_score BETWEEN 0 AND 100);

-- 2) Cache partagé des enrichissements prospects.
-- Deux familles de clés :
--   sirene-city:<ville normalisée>  -> établissements actifs de la ville
--   pagespeed:<url normalisée>      -> score performance mobile
-- Partagé entre utilisateurs : ces données publiques ne sont pas
-- spécifiques à un compte.

CREATE TABLE enrichment_cache (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cache_key   TEXT NOT NULL UNIQUE,
  payload     JSONB NOT NULL,
  expires_at  TIMESTAMPTZ NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_enrichment_cache_key ON enrichment_cache(cache_key);

-- Accès exclusivement via l'Edge Function (service role, bypass RLS).
-- Aucune policy : les clients ne lisent ni n'écrivent directement.
ALTER TABLE enrichment_cache ENABLE ROW LEVEL SECURITY;

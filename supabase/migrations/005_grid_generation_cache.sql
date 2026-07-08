-- Migration 005: cache partagé des grilles de scoring générées par IA.
-- Clé = métier normalisé (minuscules, sans accents, espaces réduits).
-- Partagé entre tous les utilisateurs : si un métier a déjà été généré,
-- la grille est servie depuis le cache sans appel IA.

CREATE TABLE grid_generation_cache (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cache_key   TEXT NOT NULL UNIQUE,
  business    TEXT NOT NULL,
  grid        JSONB NOT NULL,
  model       TEXT,
  hit_count   INT NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_grid_generation_cache_key ON grid_generation_cache(cache_key);

-- Accès exclusivement via l'Edge Function (service role, bypass RLS).
-- Aucune policy : les clients ne lisent ni n'écrivent directement.
ALTER TABLE grid_generation_cache ENABLE ROW LEVEL SECURITY;

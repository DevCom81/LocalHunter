-- Migration 014 : qualité du rapprochement SIRENE (option B3).
-- Colonnes additives ; le cache d'enrichissement bascule sur le préfixe sirene_v2: côté Edge.

ALTER TABLE prospects
  ADD COLUMN IF NOT EXISTS sirene_match_score INT
    CHECK (sirene_match_score IS NULL OR sirene_match_score BETWEEN 0 AND 100),
  ADD COLUMN IF NOT EXISTS sirene_match_ambiguous BOOLEAN NOT NULL DEFAULT false;

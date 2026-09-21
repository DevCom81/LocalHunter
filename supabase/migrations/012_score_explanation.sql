-- Migration 012 : persistance de l'explicabilité du score (option B1).
-- Colonnes additives, rétrocompatibles : les scores existants restent lisibles.
-- Si confidence_score IS NULL, le client recalcule à la volée (ScoreExplanationBuilder).

ALTER TABLE prospect_scores
  ADD COLUMN IF NOT EXISTS confidence_score INT
    CHECK (confidence_score IS NULL OR confidence_score BETWEEN 0 AND 100),
  ADD COLUMN IF NOT EXISTS filled_fields INT
    CHECK (filled_fields IS NULL OR filled_fields >= 0),
  ADD COLUMN IF NOT EXISTS total_fields INT
    CHECK (total_fields IS NULL OR total_fields >= 0),
  ADD COLUMN IF NOT EXISTS missing_fields JSONB NOT NULL DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS contributions JSONB NOT NULL DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS score_warnings JSONB NOT NULL DEFAULT '[]';

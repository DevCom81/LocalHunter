-- Phase 8 : scores FIT / OPPORTUNITY optionnels (nullable = rétrocompat).
-- Le score global /100 reste la référence priorités / quotas.

ALTER TABLE prospect_scores
  ADD COLUMN IF NOT EXISTS fit_score INT
    CHECK (fit_score IS NULL OR fit_score BETWEEN 0 AND 100),
  ADD COLUMN IF NOT EXISTS opportunity_score INT
    CHECK (opportunity_score IS NULL OR opportunity_score BETWEEN 0 AND 100);

COMMENT ON COLUMN prospect_scores.fit_score IS
  'Correspondance avec la cible (0-100). Null = score pré-Phase 8.';
COMMENT ON COLUMN prospect_scores.opportunity_score IS
  'Opportunité / timing (0-100). Null si aucun critère OPP ou pré-Phase 8.';

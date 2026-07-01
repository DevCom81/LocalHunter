-- Migration 004: scoring Phase 2 — custom fields, grid configs, dynamic scores

ALTER TABLE prospects
  ADD COLUMN IF NOT EXISTS custom_fields JSONB NOT NULL DEFAULT '{}';

ALTER TABLE scoring_grids
  ADD COLUMN IF NOT EXISTS exclusion_config JSONB NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS recommendation_config JSONB NOT NULL DEFAULT '{}';

ALTER TABLE prospect_scores
  ADD COLUMN IF NOT EXISTS component_scores JSONB NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS sub_scores JSONB NOT NULL DEFAULT '{}';

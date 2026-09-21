-- Migration 016 : statut Google Places (businessStatus) — option B5.

ALTER TABLE prospects
  ADD COLUMN IF NOT EXISTS google_business_status TEXT;

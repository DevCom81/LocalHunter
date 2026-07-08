-- Migration 009 : identité et finances des prospects.
-- SIRET (SIRENE) ; dirigeant, chiffre d'affaires et résultat net
-- (API Recherche d'entreprises — bilans INPI).

ALTER TABLE prospects
  ADD COLUMN IF NOT EXISTS siret TEXT,
  ADD COLUMN IF NOT EXISTS annual_revenue BIGINT,
  ADD COLUMN IF NOT EXISTS annual_revenue_year INT,
  ADD COLUMN IF NOT EXISTS net_income BIGINT;

-- Le format du payload d'enrichissement change (siret, finances) :
-- on repart d'un cache vide.
TRUNCATE enrichment_cache;

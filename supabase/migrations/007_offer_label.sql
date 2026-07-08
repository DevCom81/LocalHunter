-- L'offre promue devient une propriété libre de la grille de scoring.
-- Les 4 types d'offre codés en dur (website, business_software, easy_rest, crm)
-- sont remplacés par un libellé texte porté par la grille.
-- Migration 007

-- 1) Libellé d'offre sur les grilles
ALTER TABLE scoring_grids
  ADD COLUMN IF NOT EXISTS offer_label TEXT NOT NULL DEFAULT '';

UPDATE scoring_grids
SET offer_label = 'EasyRest'
WHERE name = 'EasyRest Restauration' AND offer_label = '';

-- 2) Colonnes enum -> texte libre (les anciennes valeurs sont conservées
--    telles quelles : 'easy_rest', 'website'…, réaffichées via mapping client)
ALTER TABLE campaigns ALTER COLUMN offer_type DROP DEFAULT;
ALTER TABLE campaigns ALTER COLUMN offer_type TYPE TEXT USING offer_type::TEXT;
ALTER TABLE campaigns ALTER COLUMN offer_type DROP NOT NULL;

ALTER TABLE prospect_scores
  ALTER COLUMN recommended_offer TYPE TEXT USING recommended_offer::TEXT;

ALTER TABLE ai_recommendations
  ALTER COLUMN best_offer TYPE TEXT USING best_offer::TEXT;

DROP TYPE IF EXISTS offer_type;

-- 3) Cache de génération IA : les grilles en cache utilisent l'ancien format
--    de recommandation (offer_type). On repart d'un cache vide.
TRUNCATE grid_generation_cache;

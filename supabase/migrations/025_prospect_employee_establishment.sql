-- Phase 10 : effectif et nombre d'établissements (nullable = inconnu ≠ 0).
-- Sources : API Recherche d'entreprises (tranche → borne basse ; nb établissements).

ALTER TABLE prospects
  ADD COLUMN IF NOT EXISTS employee_count INT
    CHECK (employee_count IS NULL OR employee_count >= 0),
  ADD COLUMN IF NOT EXISTS establishment_count INT
    CHECK (establishment_count IS NULL OR establishment_count >= 0);

COMMENT ON COLUMN prospects.employee_count IS
  'Effectif estimé (borne basse tranche INSEE). Null = inconnu.';
COMMENT ON COLUMN prospects.establishment_count IS
  'Nombre d''établissements (ouverts si dispo). Null = inconnu.';

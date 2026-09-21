-- Phase 7 : profil de cible optionnel sur la campagne.
-- La géographie (city, radius_km, sector) reste le filtre Places actuel.
-- Rétrocompat : NULL = campagnes existantes inchangées.

ALTER TABLE campaigns
  ADD COLUMN IF NOT EXISTS target_profile JSONB;

COMMENT ON COLUMN campaigns.target_profile IS
  'Profil de cible optionnel (offre, résumé, signaux, exclusions). '
  'Géo opérationnelle = city + radius_km (+ sector Places).';

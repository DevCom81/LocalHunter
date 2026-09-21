-- Neutralise les libellés produit « EasyRest » (exemples perso / legacy).
-- Ne touche pas aux scores ni aux clés techniques (easy_rest_score).

UPDATE scoring_grids
SET
  name = 'Restauration locale',
  offer_label = CASE
    WHEN offer_label = 'EasyRest' THEN ''
    ELSE offer_label
  END
WHERE name = 'EasyRest Restauration';

UPDATE scoring_criteria
SET label = 'Score restauration'
WHERE criterion_key = 'easy_rest_score'
  AND label IN ('EasyRestScore', 'EasyRest Score', 'EasyRest');

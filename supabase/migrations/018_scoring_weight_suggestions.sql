-- Migration 018 : suggestions de poids de grille depuis feedback CRM (option C2).
-- Jamais d'application silencieuse : status pending → accepted | ignored uniquement.

CREATE TABLE IF NOT EXISTS scoring_weight_suggestions (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  grid_id               UUID NOT NULL REFERENCES scoring_grids(id) ON DELETE CASCADE,
  criterion_key         TEXT NOT NULL,
  criterion_label       TEXT NOT NULL DEFAULT '',
  current_max_points    INT NOT NULL CHECK (current_max_points >= 0),
  suggested_max_points  INT NOT NULL CHECK (suggested_max_points >= 0),
  rationale             TEXT NOT NULL DEFAULT '',
  evidence              JSONB NOT NULL DEFAULT '{}'::jsonb,
  status                TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'ignored')),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  resolved_at           TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_weight_suggestions_grid_status
  ON scoring_weight_suggestions (grid_id, status);

CREATE INDEX IF NOT EXISTS idx_weight_suggestions_user
  ON scoring_weight_suggestions (user_id);

ALTER TABLE scoring_weight_suggestions ENABLE ROW LEVEL SECURITY;

CREATE POLICY scoring_weight_suggestions_owner ON scoring_weight_suggestions
  FOR ALL TO authenticated
  USING (
    user_id = auth.uid()
    AND grid_id IN (SELECT id FROM scoring_grids WHERE user_id = auth.uid())
  )
  WITH CHECK (
    user_id = auth.uid()
    AND grid_id IN (SELECT id FROM scoring_grids WHERE user_id = auth.uid())
  );

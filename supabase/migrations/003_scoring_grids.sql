-- Migration 003: grilles de scoring par campagne

CREATE TABLE scoring_grids (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  description TEXT,
  is_template BOOLEAN NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE scoring_criteria (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  grid_id      UUID NOT NULL REFERENCES scoring_grids(id) ON DELETE CASCADE,
  criterion_key TEXT NOT NULL,
  kind         TEXT NOT NULL CHECK (kind IN ('component', 'sub_score', 'exclusion')),
  label        TEXT NOT NULL,
  max_points   INT NOT NULL DEFAULT 0,
  star_multiplier NUMERIC(4,2) NOT NULL DEFAULT 1.0,
  rule_config  JSONB DEFAULT '{}',
  sort_order   INT NOT NULL DEFAULT 0,
  is_active    BOOLEAN NOT NULL DEFAULT true,
  UNIQUE(grid_id, criterion_key)
);

ALTER TABLE campaigns
  ADD COLUMN scoring_grid_id UUID REFERENCES scoring_grids(id) ON DELETE SET NULL;

CREATE INDEX idx_scoring_criteria_grid ON scoring_criteria(grid_id);

ALTER TABLE scoring_grids ENABLE ROW LEVEL SECURITY;
ALTER TABLE scoring_criteria ENABLE ROW LEVEL SECURITY;

CREATE POLICY scoring_grids_owner ON scoring_grids
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY scoring_criteria_owner ON scoring_criteria
  FOR ALL USING (
    grid_id IN (SELECT id FROM scoring_grids WHERE user_id = auth.uid())
  );

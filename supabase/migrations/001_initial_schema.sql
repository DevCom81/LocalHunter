-- LocalHunter MVP — schéma initial
-- Migration 001

CREATE TYPE offer_type AS ENUM (
  'website', 'business_software', 'easy_rest', 'crm'
);

CREATE TYPE prospect_status AS ENUM (
  'new', 'contacted', 'interested', 'proposal', 'won', 'lost', 'excluded'
);

CREATE TYPE priority_level AS ENUM ('high', 'medium', 'low', 'excluded');

CREATE TYPE export_format AS ENUM ('csv', 'xlsx');

-- campaigns
CREATE TABLE campaigns (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  sector        TEXT NOT NULL,
  city          TEXT NOT NULL,
  radius_km     INT NOT NULL CHECK (radius_km > 0),
  target_count  INT NOT NULL CHECK (target_count > 0),
  offer_type    offer_type NOT NULL DEFAULT 'easy_rest',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- prospects
CREATE TABLE prospects (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id       UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  name              TEXT NOT NULL,
  city              TEXT,
  address           TEXT,
  manager_name      TEXT,
  email             TEXT,
  phone             TEXT,
  website           TEXT,
  facebook_url      TEXT,
  instagram_url     TEXT,
  google_rating     NUMERIC(2,1),
  google_reviews    INT DEFAULT 0,
  category          TEXT,
  status            prospect_status NOT NULL DEFAULT 'new',
  is_excluded       BOOLEAN NOT NULL DEFAULT false,
  exclusion_reason  TEXT,
  siren             TEXT,
  naf_code          TEXT,
  legal_form        TEXT,
  google_place_id   TEXT,
  enriched_at       TIMESTAMPTZ,
  enrichment_source TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- prospect_scores
CREATE TABLE prospect_scores (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prospect_id          UUID NOT NULL UNIQUE REFERENCES prospects(id) ON DELETE CASCADE,
  global_score         INT CHECK (global_score BETWEEN 0 AND 100),
  accessibility_score  INT,
  website_opportunity  INT,
  software_opportunity INT,
  commercial_health    INT,
  site_score           NUMERIC(2,1),
  software_score       NUMERIC(2,1),
  easy_rest_score      NUMERIC(2,1),
  accessibility_stars  NUMERIC(2,1),
  digital_maturity     NUMERIC(2,1),
  false_positive_risk  NUMERIC(2,1),
  priority             priority_level,
  recommended_offer    offer_type,
  computed_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  scoring_version      INT NOT NULL DEFAULT 1
);

-- ai_recommendations
CREATE TABLE ai_recommendations (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prospect_id       UUID NOT NULL REFERENCES prospects(id) ON DELETE CASCADE,
  priority          priority_level,
  best_offer        offer_type,
  main_reason       TEXT,
  sales_angle       TEXT,
  facebook_message  TEXT,
  short_email       TEXT,
  call_opener       TEXT,
  likely_objections JSONB DEFAULT '[]',
  llm_provider      TEXT,
  generated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- contact_history
CREATE TABLE contact_history (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prospect_id  UUID NOT NULL REFERENCES prospects(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  channel      TEXT NOT NULL,
  note         TEXT,
  contacted_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- scoring_rules
CREATE TABLE scoring_rules (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rule_key   TEXT NOT NULL,
  weight     NUMERIC(4,2) NOT NULL,
  threshold  NUMERIC(4,2),
  is_active  BOOLEAN NOT NULL DEFAULT true,
  UNIQUE(user_id, rule_key)
);

-- exports
CREATE TABLE exports (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  campaign_id UUID REFERENCES campaigns(id) ON DELETE SET NULL,
  format      export_format NOT NULL,
  file_path   TEXT,
  row_count   INT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- indexes
CREATE INDEX idx_campaigns_user ON campaigns(user_id);
CREATE INDEX idx_prospects_campaign ON prospects(campaign_id);
CREATE INDEX idx_prospects_status ON prospects(status);
CREATE INDEX idx_scores_global ON prospect_scores(global_score DESC);
CREATE INDEX idx_scores_priority ON prospect_scores(priority);

-- updated_at trigger
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER campaigns_updated_at
  BEFORE UPDATE ON campaigns
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER prospects_updated_at
  BEFORE UPDATE ON prospects
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- RLS
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE prospects ENABLE ROW LEVEL SECURITY;
ALTER TABLE prospect_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE scoring_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE exports ENABLE ROW LEVEL SECURITY;

CREATE POLICY campaigns_owner ON campaigns
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY prospects_owner ON prospects
  FOR ALL USING (
    campaign_id IN (SELECT id FROM campaigns WHERE user_id = auth.uid())
  );

CREATE POLICY scores_owner ON prospect_scores
  FOR ALL USING (
    prospect_id IN (
      SELECT p.id FROM prospects p
      JOIN campaigns c ON c.id = p.campaign_id
      WHERE c.user_id = auth.uid()
    )
  );

CREATE POLICY ai_owner ON ai_recommendations
  FOR ALL USING (
    prospect_id IN (
      SELECT p.id FROM prospects p
      JOIN campaigns c ON c.id = p.campaign_id
      WHERE c.user_id = auth.uid()
    )
  );

CREATE POLICY contact_owner ON contact_history
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY rules_owner ON scoring_rules
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY exports_owner ON exports
  FOR ALL USING (user_id = auth.uid());

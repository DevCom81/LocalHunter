-- Migration 015 : profil commercial utilisateur (option B4).
-- Un profil par utilisateur ; injection IA uniquement si validated_at IS NOT NULL.

CREATE TABLE IF NOT EXISTS commercial_profiles (
  user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  activity TEXT NOT NULL DEFAULT '',
  offer TEXT NOT NULL DEFAULT '',
  target_client_type TEXT NOT NULL DEFAULT '',
  problem_solved TEXT NOT NULL DEFAULT '',
  average_basket TEXT NOT NULL DEFAULT '',
  service_area TEXT NOT NULL DEFAULT '',
  client_size TEXT NOT NULL DEFAULT '',
  positive_signals TEXT NOT NULL DEFAULT '',
  negative_signals TEXT NOT NULL DEFAULT '',
  exclusion_criteria TEXT NOT NULL DEFAULT '',
  version INT NOT NULL DEFAULT 1 CHECK (version >= 1),
  validated_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE commercial_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY commercial_profiles_owner ON commercial_profiles
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

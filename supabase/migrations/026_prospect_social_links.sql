-- Phase 11 : URLs réseaux sociaux + horodatage d'analyse (null = non scanné).
ALTER TABLE prospects
  ADD COLUMN IF NOT EXISTS linkedin_url TEXT,
  ADD COLUMN IF NOT EXISTS tiktok_url TEXT,
  ADD COLUMN IF NOT EXISTS youtube_url TEXT,
  ADD COLUMN IF NOT EXISTS x_url TEXT,
  ADD COLUMN IF NOT EXISTS social_checked_at TIMESTAMPTZ;

NOTIFY pgrst, 'reload schema';

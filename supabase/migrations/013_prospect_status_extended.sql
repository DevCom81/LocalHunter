-- Migration 013 : extension des statuts CRM (option B2).
-- Les 7 valeurs existantes sont conservées ; ADD VALUE est rétrocompatible.

ALTER TYPE prospect_status ADD VALUE IF NOT EXISTS 'to_study';
ALTER TYPE prospect_status ADD VALUE IF NOT EXISTS 'to_contact';
ALTER TYPE prospect_status ADD VALUE IF NOT EXISTS 'not_relevant';
ALTER TYPE prospect_status ADD VALUE IF NOT EXISTS 'already_equipped';
ALTER TYPE prospect_status ADD VALUE IF NOT EXISTS 'too_small';
ALTER TYPE prospect_status ADD VALUE IF NOT EXISTS 'franchise';
ALTER TYPE prospect_status ADD VALUE IF NOT EXISTS 'out_of_scope';
ALTER TYPE prospect_status ADD VALUE IF NOT EXISTS 'no_reply';
ALTER TYPE prospect_status ADD VALUE IF NOT EXISTS 'meeting';

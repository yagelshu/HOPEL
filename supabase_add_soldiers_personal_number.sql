-- ===================================================================
-- HOPEL: Add personal_number column to public.soldiers
-- Run this in your Supabase project SQL Editor to enable native column support!
-- ===================================================================

-- 1. Add personal_number column if missing
ALTER TABLE public.soldiers ADD COLUMN IF NOT EXISTS personal_number TEXT;

-- 2. Backfill personal_number from legacy name format: "ישראל ישראלי (1234567)"
UPDATE public.soldiers
SET personal_number = substring(name from '\((\d+)\)\s*$'),
    name = trim(regexp_replace(name, '\s*\(\d+\)\s*$', ''))
WHERE (personal_number IS NULL OR personal_number = '') AND name ~ '\(\d+\)\s*$';

-- 3. Add index for fast searches
CREATE INDEX IF NOT EXISTS idx_soldiers_personal_number
ON public.soldiers (unit_id, personal_number);

-- 4. Reload PostgREST schema cache immediately
NOTIFY pgrst, 'reload schema';

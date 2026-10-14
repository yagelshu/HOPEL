-- =====================================================================
-- HOPEL - MASTER FIX (safe to run multiple times)
-- Paste the whole file into Supabase > SQL Editor > Run.
-- Fixes "permission denied" errors (lost grants) and prepares the
-- soldiers table for Excel import (personal_number column).
-- =====================================================================

-- 1. Restore table privileges (root cause of "nothing saves / permission denied")
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO authenticated;

-- Update checker runs before login
DO $$ BEGIN
  IF to_regclass('public.app_versions') IS NOT NULL THEN
    EXECUTE 'GRANT SELECT ON public.app_versions TO anon';
  END IF;
  IF to_regclass('public.units') IS NOT NULL THEN
    EXECUTE 'GRANT SELECT ON public.units TO anon';
  END IF;
END $$;

-- 2. Soldiers: auto id + personal number
ALTER TABLE public.soldiers ALTER COLUMN id SET DEFAULT gen_random_uuid()::text;
ALTER TABLE public.soldiers ADD COLUMN IF NOT EXISTS personal_number TEXT;

-- Backfill personal_number from legacy names like "ישראל ישראלי (1234567)"
UPDATE public.soldiers
SET personal_number = substring(name from '\((\d+)\)\s*$'),
    name = trim(regexp_replace(name, '\s*\(\d+\)\s*$', ''))
WHERE personal_number IS NULL AND name ~ '\(\d+\)\s*$';

-- One personal number per unit (lets import update instead of duplicating)
CREATE UNIQUE INDEX IF NOT EXISTS soldiers_unit_personal_number_uidx
  ON public.soldiers (unit_id, personal_number);

-- 3. Permissive policy for authenticated users (MVP)
ALTER TABLE public.soldiers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow authenticated all" ON public.soldiers;
CREATE POLICY "Allow authenticated all" ON public.soldiers
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 4. Medics on standby: allow manually-added medics (no app account)
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_on_standby BOOLEAN DEFAULT false;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_manual BOOLEAN DEFAULT false;
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_id_fkey;
DROP POLICY IF EXISTS "Allow authenticated all" ON public.users;
CREATE POLICY "Allow authenticated all" ON public.users
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 5. Daily schedule policy
DO $$ BEGIN
  IF to_regclass('public.daily_schedule') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.daily_schedule ENABLE ROW LEVEL SECURITY';
    EXECUTE 'DROP POLICY IF EXISTS "Allow authenticated all" ON public.daily_schedule';
    EXECUTE 'CREATE POLICY "Allow authenticated all" ON public.daily_schedule FOR ALL TO authenticated USING (true) WITH CHECK (true)';
  END IF;
END $$;

NOTIFY pgrst, 'reload schema';

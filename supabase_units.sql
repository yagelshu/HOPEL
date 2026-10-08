-- SQL Script for Phase 6: Unit Management (Join Codes)
-- Run this in your Supabase SQL Editor

-- 1. Add join_code to units table
ALTER TABLE public.units ADD COLUMN IF NOT EXISTS join_code TEXT UNIQUE;

-- 2. Create a function to auto-generate a 6-character random alphanumeric join code for new units
CREATE OR REPLACE FUNCTION generate_join_code() RETURNS TRIGGER AS $$
DECLARE
  new_code TEXT;
  done BOOLEAN := false;
BEGIN
  WHILE NOT done LOOP
    new_code := upper(substring(md5(random()::text) from 1 for 6));
    BEGIN
      NEW.join_code := new_code;
      done := true;
    EXCEPTION WHEN unique_violation THEN
      -- Loop again if code exists
    END;
  END LOOP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Create a trigger to auto-assign join code on insert if not provided
DROP TRIGGER IF EXISTS trigger_generate_join_code ON public.units;
CREATE TRIGGER trigger_generate_join_code
BEFORE INSERT ON public.units
FOR EACH ROW
WHEN (NEW.join_code IS NULL)
EXECUTE FUNCTION generate_join_code();

-- 4. Give Platoon C a join code for existing testing ('AAAAAA')
UPDATE public.units SET join_code = 'AAAAAA' WHERE id = '00000000-0000-0000-0000-000000000001' AND join_code IS NULL;

-- 5. Fix Units RLS to allow authenticated users to insert units
DROP POLICY IF EXISTS "Allow authenticated insert" ON public.units;
CREATE POLICY "Allow authenticated insert" ON public.units FOR INSERT TO authenticated WITH CHECK (true);

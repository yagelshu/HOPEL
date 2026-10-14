-- =====================================================================
-- HOPEL - CONSOLIDATED SCHEMA (single source of truth for the database)
--
-- HOW TO USE: Supabase Dashboard > SQL Editor > New query > paste this
-- whole file > Run.  Safe to run any number of times (idempotent).
--
-- When the app needs a DB change, THIS file is updated and the
-- schema version below is bumped. The app checks the version on startup
-- and shows a clear warning if the DB is behind.
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ---------------------------------------------------------------------
-- 1. TABLES & COLUMNS
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.units (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL
);
ALTER TABLE public.units ADD COLUMN IF NOT EXISTS join_code TEXT;

CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'COMBAT_MEDIC',
  unit_id UUID REFERENCES public.units(id)
);
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS active_deployment_id UUID;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS competence_points INTEGER DEFAULT 0;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_on_standby BOOLEAN DEFAULT false;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_manual BOOLEAN DEFAULT false;
-- Manually-added medics have no auth account
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_id_fkey;

CREATE TABLE IF NOT EXISTS public.deployments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  start_date TEXT NOT NULL,
  end_date TEXT,
  unit_id UUID REFERENCES public.units(id) ON DELETE CASCADE,
  is_active BOOLEAN DEFAULT true
);
ALTER TABLE public.deployments ADD COLUMN IF NOT EXISTS summary_data JSONB;

CREATE TABLE IF NOT EXISTS public.soldiers (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  name TEXT NOT NULL,
  platoon TEXT,
  unit_id UUID REFERENCES public.units(id),
  phone_number TEXT
);
ALTER TABLE public.soldiers ADD COLUMN IF NOT EXISTS personal_number TEXT;

CREATE TABLE IF NOT EXISTS public.medical_cases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  soldier_id TEXT NOT NULL,
  status TEXT NOT NULL,
  description TEXT,
  follow_up_date TEXT,
  created_date TEXT NOT NULL,
  updated_date TEXT,
  closed_date TEXT,
  image_path TEXT
);
ALTER TABLE public.medical_cases ADD COLUMN IF NOT EXISTS deployment_id UUID;
ALTER TABLE public.medical_cases ADD COLUMN IF NOT EXISTS unit_id UUID;
ALTER TABLE public.medical_cases ADD COLUMN IF NOT EXISTS category TEXT;
ALTER TABLE public.medical_cases ADD COLUMN IF NOT EXISTS severity TEXT;
ALTER TABLE public.medical_cases ALTER COLUMN category SET DEFAULT 'שגרת מרפאה';
ALTER TABLE public.medical_cases ALTER COLUMN severity SET DEFAULT 'שגרה';

CREATE TABLE IF NOT EXISTS public.equipment (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 0,
  minimum_required INTEGER NOT NULL DEFAULT 0,
  expiration_date TEXT,
  status TEXT NOT NULL DEFAULT 'IN_STOCK',
  category TEXT DEFAULT 'כללי',
  item_type TEXT DEFAULT 'מתכלה',
  unit_id UUID REFERENCES public.units(id)
);

CREATE TABLE IF NOT EXISTS public.equipment_catalog (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  item_type TEXT NOT NULL,
  minimum_required INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.equipment_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  equipment_id UUID NOT NULL REFERENCES public.equipment(id) ON DELETE CASCADE,
  medic_id UUID NOT NULL,
  verification_status TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS public.daily_schedule (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  unit_id UUID REFERENCES public.units(id) ON DELETE CASCADE,
  time TEXT,
  title TEXT,
  actor TEXT,
  icon TEXT,
  is_done BOOLEAN DEFAULT false
);

CREATE TABLE IF NOT EXISTS public.notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  unit_id UUID NOT NULL REFERENCES public.units(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  content TEXT NOT NULL,
  is_private BOOLEAN NOT NULL DEFAULT false,
  created_at TEXT NOT NULL DEFAULT now()::text,
  updated_at TEXT NOT NULL DEFAULT now()::text
);

CREATE TABLE IF NOT EXISTS public.learning_content (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'PDF',
  category TEXT NOT NULL,
  url TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS public.app_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  version TEXT NOT NULL,
  build_number INTEGER NOT NULL,
  download_url TEXT NOT NULL,
  release_notes TEXT,
  is_mandatory BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- 2. DATA FIXES (backfills)
-- ---------------------------------------------------------------------
-- Legacy soldiers stored "Name (1234567)" in the name column
UPDATE public.soldiers
SET personal_number = substring(name from '\((\d+)\)\s*$'),
    name = trim(regexp_replace(name, '\s*\(\d+\)\s*$', ''))
WHERE personal_number IS NULL AND name ~ '\(\d+\)\s*$';

-- Cases get a unit_id (needed for offline sync + security rules)
UPDATE public.medical_cases m SET unit_id = d.unit_id
FROM public.deployments d
WHERE m.unit_id IS NULL AND m.deployment_id = d.id;

UPDATE public.medical_cases m SET unit_id = s.unit_id
FROM public.soldiers s
WHERE m.unit_id IS NULL AND m.soldier_id::text = s.id::text;

-- ---------------------------------------------------------------------
-- 3. INDEXES
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS soldiers_unit_idx ON public.soldiers (unit_id);
CREATE INDEX IF NOT EXISTS medical_cases_unit_idx ON public.medical_cases (unit_id);
CREATE INDEX IF NOT EXISTS medical_cases_deployment_idx ON public.medical_cases (deployment_id);
CREATE INDEX IF NOT EXISTS equipment_unit_idx ON public.equipment (unit_id);

DO $$ BEGIN
  CREATE UNIQUE INDEX IF NOT EXISTS soldiers_unit_pn_uidx
    ON public.soldiers (unit_id, personal_number) WHERE personal_number IS NOT NULL;
EXCEPTION WHEN unique_violation THEN
  RAISE NOTICE 'Duplicate personal numbers exist - unique index skipped (app de-duplicates anyway)';
END $$;

-- ---------------------------------------------------------------------
-- 4. HELPER: current user's unit (SECURITY DEFINER avoids RLS recursion)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.my_unit_id()
RETURNS UUID LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT unit_id FROM public.users WHERE id = auth.uid()
$$;

-- Fill unit_id automatically when a client omits it (older app versions)
CREATE OR REPLACE FUNCTION public.fill_unit_id()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.unit_id IS NULL THEN NEW.unit_id := public.my_unit_id(); END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS fill_unit_id ON public.medical_cases;
CREATE TRIGGER fill_unit_id BEFORE INSERT OR UPDATE ON public.medical_cases
  FOR EACH ROW EXECUTE FUNCTION public.fill_unit_id();
DROP TRIGGER IF EXISTS fill_unit_id ON public.soldiers;
CREATE TRIGGER fill_unit_id BEFORE INSERT OR UPDATE ON public.soldiers
  FOR EACH ROW EXECUTE FUNCTION public.fill_unit_id();

-- ---------------------------------------------------------------------
-- 5. ROW LEVEL SECURITY - wipe every old policy, recreate a clean set
--    Rule: a user sees and edits ONLY their own unit's data.
-- ---------------------------------------------------------------------
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT policyname, tablename FROM pg_policies
    WHERE schemaname = 'public' AND tablename IN (
      'units','users','deployments','soldiers','medical_cases','equipment',
      'equipment_catalog','equipment_assignments','daily_schedule','notes',
      'learning_content','app_versions')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', r.policyname, r.tablename);
  END LOOP;
END $$;

ALTER TABLE public.units                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deployments           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.soldiers              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medical_cases         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipment             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipment_catalog     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipment_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_schedule        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notes                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_content      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_versions          ENABLE ROW LEVEL SECURITY;

-- units: see/rename own unit (create/join go through RPCs below)
CREATE POLICY units_select ON public.units FOR SELECT TO authenticated USING (id = public.my_unit_id());
CREATE POLICY units_update ON public.units FOR UPDATE TO authenticated USING (id = public.my_unit_id());

-- users: own row + everyone in my unit (medics list, standby toggles)
CREATE POLICY users_select ON public.users FOR SELECT TO authenticated
  USING (id = auth.uid() OR unit_id = public.my_unit_id());
CREATE POLICY users_insert ON public.users FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid() OR unit_id = public.my_unit_id());
CREATE POLICY users_update ON public.users FOR UPDATE TO authenticated
  USING (id = auth.uid() OR unit_id = public.my_unit_id())
  WITH CHECK (id = auth.uid() OR unit_id = public.my_unit_id());
CREATE POLICY users_delete ON public.users FOR DELETE TO authenticated
  USING (is_manual = true AND unit_id = public.my_unit_id());

-- unit-scoped tables
CREATE POLICY deployments_all ON public.deployments FOR ALL TO authenticated
  USING (unit_id = public.my_unit_id()) WITH CHECK (unit_id = public.my_unit_id());
CREATE POLICY soldiers_all ON public.soldiers FOR ALL TO authenticated
  USING (unit_id = public.my_unit_id()) WITH CHECK (unit_id = public.my_unit_id());
CREATE POLICY medical_cases_all ON public.medical_cases FOR ALL TO authenticated
  USING (unit_id = public.my_unit_id()) WITH CHECK (unit_id = public.my_unit_id());
CREATE POLICY equipment_all ON public.equipment FOR ALL TO authenticated
  USING (unit_id = public.my_unit_id()) WITH CHECK (unit_id = public.my_unit_id());
CREATE POLICY daily_schedule_all ON public.daily_schedule FOR ALL TO authenticated
  USING (unit_id = public.my_unit_id()) WITH CHECK (unit_id = public.my_unit_id());

CREATE POLICY equipment_assignments_all ON public.equipment_assignments FOR ALL TO authenticated
  USING (medic_id = auth.uid() OR equipment_id IN (SELECT id FROM public.equipment WHERE unit_id = public.my_unit_id()))
  WITH CHECK (equipment_id IN (SELECT id FROM public.equipment WHERE unit_id = public.my_unit_id()));

-- notes: shared notes visible to unit, private notes only to author
CREATE POLICY notes_select ON public.notes FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR (is_private = false AND unit_id = public.my_unit_id()));
CREATE POLICY notes_insert ON public.notes FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid() AND unit_id = public.my_unit_id());
CREATE POLICY notes_update ON public.notes FOR UPDATE TO authenticated USING (user_id = auth.uid());
CREATE POLICY notes_delete ON public.notes FOR DELETE TO authenticated USING (user_id = auth.uid());

-- global read-only catalogs
CREATE POLICY equipment_catalog_read ON public.equipment_catalog FOR SELECT TO authenticated USING (true);
CREATE POLICY learning_content_read ON public.learning_content FOR SELECT TO authenticated USING (true);
CREATE POLICY app_versions_read ON public.app_versions FOR SELECT TO anon, authenticated USING (true);

-- ---------------------------------------------------------------------
-- 6. PRIVILEGES (RLS above decides which rows)
-- ---------------------------------------------------------------------
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT SELECT ON public.app_versions TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;

-- ---------------------------------------------------------------------
-- 7. NEW USER -> profile row automatically (works even with email confirm)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  BEGIN
    INSERT INTO public.users (id, name, role)
    VALUES (NEW.id, COALESCE(NULLIF(NEW.raw_user_meta_data->>'name', ''), split_part(NEW.email, '@', 1)), 'COMBAT_MEDIC')
    ON CONFLICT (id) DO NOTHING;
  EXCEPTION WHEN others THEN
    -- never block sign-up because of the profile row
    NULL;
  END;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ---------------------------------------------------------------------
-- 8. RPCs: create / join unit atomically (one call, all-or-nothing)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.ensure_my_profile()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.users (id, name, role)
  SELECT u.id, COALESCE(NULLIF(u.raw_user_meta_data->>'name', ''), split_part(u.email, '@', 1)), 'COMBAT_MEDIC'
  FROM auth.users u WHERE u.id = auth.uid()
  ON CONFLICT (id) DO NOTHING;
END $$;

CREATE OR REPLACE FUNCTION public.create_unit(p_name TEXT)
RETURNS json LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid  UUID := auth.uid();
  v_unit UUID := gen_random_uuid();
  v_dep  UUID := gen_random_uuid();
  v_code TEXT;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
  IF COALESCE(trim(p_name), '') = '' THEN RAISE EXCEPTION 'unit name required'; END IF;

  LOOP
    v_code := upper(substring(md5(random()::text) FROM 1 FOR 6));
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.units WHERE join_code = v_code);
  END LOOP;

  PERFORM public.ensure_my_profile();

  INSERT INTO public.units (id, name, join_code) VALUES (v_unit, trim(p_name), v_code);
  INSERT INTO public.deployments (id, name, start_date, unit_id, is_active)
  VALUES (v_dep, 'תעסוקה ראשונית', to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'), v_unit, true);

  UPDATE public.users
  SET role = 'COMPANY_MEDIC', unit_id = v_unit, active_deployment_id = v_dep
  WHERE id = v_uid;

  INSERT INTO public.equipment (id, name, quantity, minimum_required, status, category, item_type, unit_id)
  SELECT gen_random_uuid(), c.name, c.minimum_required, c.minimum_required, 'IN_STOCK', c.category, c.item_type, v_unit
  FROM public.equipment_catalog c;

  RETURN json_build_object('unit_id', v_unit, 'name', trim(p_name), 'join_code', v_code, 'deployment_id', v_dep);
END $$;

CREATE OR REPLACE FUNCTION public.join_unit(p_code TEXT)
RETURNS json LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid  UUID := auth.uid();
  v_unit public.units%ROWTYPE;
  v_dep  UUID;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;

  SELECT * INTO v_unit FROM public.units WHERE join_code = upper(trim(p_code));
  IF NOT FOUND THEN RETURN NULL; END IF;

  SELECT id INTO v_dep FROM public.deployments
  WHERE unit_id = v_unit.id AND is_active = true
  ORDER BY start_date DESC LIMIT 1;

  PERFORM public.ensure_my_profile();

  UPDATE public.users
  SET role = 'COMBAT_MEDIC', unit_id = v_unit.id, active_deployment_id = v_dep
  WHERE id = v_uid;

  RETURN json_build_object('unit_id', v_unit.id, 'name', v_unit.name, 'join_code', v_unit.join_code, 'deployment_id', v_dep);
END $$;

-- ---------------------------------------------------------------------
-- 9. SCHEMA VERSION (the app checks this on startup)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.hopel_schema_version()
RETURNS INTEGER LANGUAGE sql IMMUTABLE AS $$ SELECT 2 $$;

GRANT EXECUTE ON FUNCTION public.hopel_schema_version() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.my_unit_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.ensure_my_profile() TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_unit(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.join_unit(TEXT) TO authenticated;

NOTIFY pgrst, 'reload schema';

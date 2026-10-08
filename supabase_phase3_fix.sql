-- Phase 3 Schema Fixes
-- This script adds missing tables and columns to Supabase that were present in SQLite MVP

-- 1. Add missing columns to existing tables
ALTER TABLE public.units ADD COLUMN IF NOT EXISTS join_code TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS active_deployment_id UUID;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS competence_points INTEGER DEFAULT 0;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_on_standby BOOLEAN DEFAULT false;
ALTER TABLE public.medical_cases ADD COLUMN IF NOT EXISTS deployment_id UUID;

-- 2. Create equipment_assignments table
CREATE TABLE IF NOT EXISTS public.equipment_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    equipment_id UUID NOT NULL REFERENCES public.equipment(id) ON DELETE CASCADE,
    medic_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    verification_status TEXT NOT NULL
);

-- 3. Create deployments table
CREATE TABLE IF NOT EXISTS public.deployments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    start_date TEXT NOT NULL,
    end_date TEXT,
    unit_id UUID REFERENCES public.units(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT true
);

-- 4. Create notes table
CREATE TABLE IF NOT EXISTS public.notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    unit_id UUID NOT NULL REFERENCES public.units(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_private BOOLEAN NOT NULL DEFAULT false,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- 5. Enable RLS on new tables
ALTER TABLE public.equipment_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deployments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;

-- 6. Add RLS Policies for new tables (Allow all authenticated users for now)
DROP POLICY IF EXISTS "Allow authenticated all" ON public.equipment_assignments;
CREATE POLICY "Allow authenticated all" ON public.equipment_assignments FOR ALL TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow authenticated all" ON public.deployments;
CREATE POLICY "Allow authenticated all" ON public.deployments FOR ALL TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow authenticated all" ON public.notes;
CREATE POLICY "Allow authenticated all" ON public.notes FOR ALL TO authenticated USING (true);

-- 7. Fix existing RLS Policies for units to allow INSERT
DROP POLICY IF EXISTS "Allow authenticated read" ON public.units;
DROP POLICY IF EXISTS "Allow authenticated all" ON public.units;
CREATE POLICY "Allow authenticated all" ON public.units FOR ALL TO authenticated USING (true);

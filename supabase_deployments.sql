-- SQL Script for Phase 5: Deployments (תעסוקות)
-- Run this in your Supabase SQL Editor

-- 1. Create Deployments Table
CREATE TABLE IF NOT EXISTS public.deployments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    start_date TEXT NOT NULL,
    end_date TEXT,
    unit_id UUID REFERENCES public.units(id),
    is_active BOOLEAN DEFAULT true
);

ALTER TABLE public.deployments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow authenticated all" ON public.deployments FOR ALL TO authenticated USING (true);

-- 2. Update Users Table (Add active_deployment_id)
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS active_deployment_id UUID REFERENCES public.deployments(id);

-- Fix RLS for Users Table (Allow inserts during registration)
DROP POLICY IF EXISTS "Allow authenticated all" ON public.users;
CREATE POLICY "Allow authenticated read" ON public.users FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow authenticated update" ON public.users FOR UPDATE TO authenticated USING (auth.uid() = id);
CREATE POLICY "Allow authenticated insert" ON public.users FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

-- 3. Update Medical Cases Table (Add deployment_id)
ALTER TABLE public.medical_cases ADD COLUMN IF NOT EXISTS deployment_id UUID REFERENCES public.deployments(id) ON DELETE CASCADE;

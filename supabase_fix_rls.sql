-- Fix RLS Policies for HOPEL App

-- 1. Units Table
ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow authenticated all" ON public.units;
CREATE POLICY "Allow authenticated all" ON public.units FOR ALL TO authenticated USING (true);

-- 2. Users Table
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow authenticated all" ON public.users;
DROP POLICY IF EXISTS "Allow authenticated read" ON public.users;
DROP POLICY IF EXISTS "Allow authenticated update" ON public.users;
DROP POLICY IF EXISTS "Allow authenticated insert" ON public.users;

-- Allow users to read all users (needed for joining units etc)
CREATE POLICY "Allow authenticated read" ON public.users FOR SELECT TO authenticated USING (true);
-- Allow users to update their own record
CREATE POLICY "Allow authenticated update" ON public.users FOR UPDATE TO authenticated USING (auth.uid() = id);
-- Allow users to insert their own record during registration
CREATE POLICY "Allow authenticated insert" ON public.users FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

-- 3. Deployments Table
ALTER TABLE public.deployments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow authenticated all" ON public.deployments;
CREATE POLICY "Allow authenticated all" ON public.deployments FOR ALL TO authenticated USING (true);

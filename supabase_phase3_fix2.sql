-- Fix constraints and column types to allow manual user insertion and string IDs

-- 1. Fix soldier ID to allow the user's typed string (personal number)
ALTER TABLE public.medical_cases DROP CONSTRAINT medical_cases_soldier_id_fkey;
ALTER TABLE public.medical_cases ALTER COLUMN soldier_id TYPE TEXT USING soldier_id::text;
ALTER TABLE public.soldiers ALTER COLUMN id TYPE TEXT USING id::text;
ALTER TABLE public.medical_cases ADD CONSTRAINT medical_cases_soldier_id_fkey FOREIGN KEY (soldier_id) REFERENCES public.soldiers(id) ON DELETE CASCADE;

-- 2. Drop foreign key constraint on users.id so dummy medics can be added in MVP
ALTER TABLE public.users DROP CONSTRAINT users_id_fkey;

-- 3. Ensure WITH CHECK policies are explicit for inserts/updates
DROP POLICY IF EXISTS "Allow authenticated all" ON public.users;
CREATE POLICY "Allow authenticated all" ON public.users FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated all" ON public.soldiers;
CREATE POLICY "Allow authenticated all" ON public.soldiers FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated all" ON public.medical_cases;
CREATE POLICY "Allow authenticated all" ON public.medical_cases FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated all" ON public.equipment;
CREATE POLICY "Allow authenticated all" ON public.equipment FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated all" ON public.daily_schedule;
CREATE POLICY "Allow authenticated all" ON public.daily_schedule FOR ALL TO authenticated USING (true) WITH CHECK (true);

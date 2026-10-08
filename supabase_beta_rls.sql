-- HOPAL Beta Readiness RLS Policies

-- 1. Drop the permissive "Allow authenticated all" policies we might have created earlier
DROP POLICY IF EXISTS "Allow authenticated all" ON public.medical_cases;
DROP POLICY IF EXISTS "Allow authenticated all" ON public.equipment;
DROP POLICY IF EXISTS "Allow authenticated all" ON public.daily_schedule;
DROP POLICY IF EXISTS "Enable all operations for all users" ON public.medical_cases;
DROP POLICY IF EXISTS "Enable all operations for all users" ON public.equipment;
DROP POLICY IF EXISTS "Enable all operations for all users" ON public.daily_schedule;

-- 2. Medical Cases RLS: Users can only see/edit cases in their active deployment
CREATE POLICY "Users can access their deployment's cases" 
ON public.medical_cases 
FOR ALL 
TO authenticated 
USING (
  deployment_id = (SELECT active_deployment_id FROM public.users WHERE id = auth.uid())
);

-- 3. Equipment RLS: Users can only see/edit inventory in their unit
CREATE POLICY "Users can access their unit's equipment" 
ON public.equipment 
FOR ALL 
TO authenticated 
USING (
  unit_id = (SELECT unit_id FROM public.users WHERE id = auth.uid())
);

-- 4. Daily Schedule RLS: Users can only see/edit tasks in their unit
CREATE POLICY "Users can access their unit's schedule" 
ON public.daily_schedule 
FOR ALL 
TO authenticated 
USING (
  unit_id = (SELECT unit_id FROM public.users WHERE id = auth.uid())
);

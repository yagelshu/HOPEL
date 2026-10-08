-- SQL Script for Phase 5: Deployments Lifecycle & Archive

-- 1. Add summary_data to Deployments table
ALTER TABLE public.deployments ADD COLUMN IF NOT EXISTS summary_data JSONB;

-- 2. Update existing archived deployments (if any) to have an end_date (if it was somehow missed)
UPDATE public.deployments 
SET end_date = start_date 
WHERE is_active = false AND end_date IS NULL;

-- 3. Ensure permissions for authenticated users on deployments table (if not already granted)
-- Note: Deployments is a shared table, so all users need to be able to read and update it.
DROP POLICY IF EXISTS "Users can update deployments" ON public.deployments;
CREATE POLICY "Users can update deployments" 
ON public.deployments 
FOR UPDATE 
TO authenticated 
USING (true);

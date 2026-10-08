-- Phase 2: Create daily_schedule table

CREATE TABLE IF NOT EXISTS public.daily_schedule (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    time TEXT NOT NULL,
    title TEXT NOT NULL,
    icon TEXT,
    is_done BOOLEAN DEFAULT FALSE,
    actor TEXT,
    unit_id UUID REFERENCES public.units(id) ON DELETE CASCADE
);

ALTER TABLE public.daily_schedule ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own unit schedule" ON public.daily_schedule;
CREATE POLICY "Users can read own unit schedule" 
ON public.daily_schedule 
FOR SELECT 
TO authenticated 
USING (unit_id IN (SELECT unit_id FROM public.users WHERE users.id = auth.uid()));

DROP POLICY IF EXISTS "Users can update own unit schedule" ON public.daily_schedule;
CREATE POLICY "Users can update own unit schedule" 
ON public.daily_schedule 
FOR UPDATE 
TO authenticated 
USING (unit_id IN (SELECT unit_id FROM public.users WHERE users.id = auth.uid()));

DROP POLICY IF EXISTS "Users can insert own unit schedule" ON public.daily_schedule;
CREATE POLICY "Users can insert own unit schedule" 
ON public.daily_schedule 
FOR INSERT 
TO authenticated 
WITH CHECK (unit_id IN (SELECT unit_id FROM public.users WHERE users.id = auth.uid()));

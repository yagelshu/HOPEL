-- SQL Script to add Notes/Logbook to HOPAL Database
-- Run this in your Supabase SQL Editor

CREATE TABLE IF NOT EXISTS public.notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    unit_id UUID NOT NULL REFERENCES public.units(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_private BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;

-- Policy 1: Users can read shared notes in their unit
DROP POLICY IF EXISTS "Users can read shared notes in their unit" ON public.notes;
CREATE POLICY "Users can read shared notes in their unit"
    ON public.notes
    FOR SELECT
    USING (
        is_private = false 
        AND unit_id IN (SELECT unit_id FROM public.users WHERE id = auth.uid())
    );

-- Policy 2: Users can read their own private notes
DROP POLICY IF EXISTS "Users can read their own private notes" ON public.notes;
CREATE POLICY "Users can read their own private notes"
    ON public.notes
    FOR SELECT
    USING (
        is_private = true 
        AND user_id = auth.uid()
    );

-- Policy 3: Users can insert notes into their unit
DROP POLICY IF EXISTS "Users can insert notes" ON public.notes;
CREATE POLICY "Users can insert notes"
    ON public.notes
    FOR INSERT
    WITH CHECK (
        unit_id IN (SELECT unit_id FROM public.users WHERE id = auth.uid())
        AND user_id = auth.uid()
    );

-- Policy 4: Users can update their own notes
DROP POLICY IF EXISTS "Users can update their own notes" ON public.notes;
CREATE POLICY "Users can update their own notes"
    ON public.notes
    FOR UPDATE
    USING (user_id = auth.uid());

-- Policy 5: Users can delete their own notes
DROP POLICY IF EXISTS "Users can delete their own notes" ON public.notes;
CREATE POLICY "Users can delete their own notes"
    ON public.notes
    FOR DELETE
    USING (user_id = auth.uid());

-- Grant privileges to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON public.notes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.notes TO anon;

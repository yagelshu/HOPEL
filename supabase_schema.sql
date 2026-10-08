-- SQL Script to setup HOPAL App Database on Supabase
-- Run this in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Units Table
CREATE TABLE IF NOT EXISTS public.units (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL
);

-- 2. Users Table (Maps to Supabase Auth)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    role TEXT NOT NULL,
    unit_id UUID REFERENCES public.units(id)
);

-- 3. Soldiers Table
CREATE TABLE IF NOT EXISTS public.soldiers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    platoon TEXT,
    unit_id UUID REFERENCES public.units(id),
    phone_number TEXT
);

-- 4. Medical Cases Table
CREATE TABLE IF NOT EXISTS public.medical_cases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    soldier_id UUID NOT NULL REFERENCES public.soldiers(id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    description TEXT,
    follow_up_date TEXT,
    created_date TEXT NOT NULL,
    updated_date TEXT,
    closed_date TEXT,
    image_path TEXT
);

-- 5. Equipment Table
CREATE TABLE IF NOT EXISTS public.equipment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 0,
    minimum_required INTEGER NOT NULL DEFAULT 0,
    expiration_date TEXT,
    status TEXT NOT NULL,
    category TEXT DEFAULT 'כללי',
    item_type TEXT DEFAULT 'מתכלה',
    unit_id UUID REFERENCES public.units(id)
);

-- Turn on Row Level Security (RLS)
ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.soldiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medical_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipment ENABLE ROW LEVEL SECURITY;

-- Create Policies (Allow all authenticated users to read/write for now, to speed up MVP beta)
CREATE POLICY "Allow authenticated read" ON public.units FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow authenticated all" ON public.users FOR ALL TO authenticated USING (true);
CREATE POLICY "Allow authenticated all" ON public.soldiers FOR ALL TO authenticated USING (true);
CREATE POLICY "Allow authenticated all" ON public.medical_cases FOR ALL TO authenticated USING (true);
CREATE POLICY "Allow authenticated all" ON public.equipment FOR ALL TO authenticated USING (true);

-- Seed Initial Unit
INSERT INTO public.units (id, name) VALUES ('00000000-0000-0000-0000-000000000001', 'פלוגה ג') ON CONFLICT DO NOTHING;

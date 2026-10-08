-- SQL Script: Add Category and Severity to Medical Cases

ALTER TABLE public.medical_cases 
ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'שגרת מרפאה';

ALTER TABLE public.medical_cases 
ADD COLUMN IF NOT EXISTS severity TEXT DEFAULT 'שגרה';

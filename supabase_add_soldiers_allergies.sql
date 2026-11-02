-- SQL Migration: Add allergies column to soldiers table
ALTER TABLE public.soldiers 
ADD COLUMN IF NOT EXISTS allergies TEXT;

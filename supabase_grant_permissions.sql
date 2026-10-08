-- Grant permissions to the authenticated role for all tables

GRANT SELECT, INSERT, UPDATE, DELETE ON public.units TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.users TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.soldiers TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.medical_cases TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.equipment TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.equipment_catalog TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.learning_content TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.daily_schedule TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.equipment_assignments TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.deployments TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.notes TO authenticated;

-- Also grant usage on schema public just in case
GRANT USAGE ON SCHEMA public TO authenticated;

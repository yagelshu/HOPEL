-- =====================================================================
-- תיקון טבלת משתמשים ב-Supabase להוספת חובשים ידנית ללא חשבון אימות
-- העתק והדבק ב-Supabase Dashboard > SQL Editor > Run
-- =====================================================================

-- 1. הוספת עמודות נדרשות
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_on_standby BOOLEAN DEFAULT false;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_manual BOOLEAN DEFAULT false;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS phone_number TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS platoon TEXT;

-- 2. הסרת אילוץ מפתח זר ל-auth.users (כדי לאפשר חובשים שטרם פתחו חשבון)
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_id_fkey;

-- 3. עדכון הרשאות RLS להוספה ומחיקה של חובשים ידניים בפלוגה
DROP POLICY IF EXISTS users_insert ON public.users;
CREATE POLICY users_insert ON public.users FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid() OR unit_id = public.my_unit_id());

DROP POLICY IF EXISTS users_delete ON public.users;
CREATE POLICY users_delete ON public.users FOR DELETE TO authenticated
  USING (id = auth.uid() OR (is_manual = true AND unit_id = public.my_unit_id()));

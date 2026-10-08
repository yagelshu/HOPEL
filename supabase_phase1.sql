-- Phase 1: Setup Catalog Tables and Seed Data
-- This script creates the global catalogs for equipment and learning content
-- and populates them with the standard IDF mock data. It is idempotent (safe to run multiple times).

-- 1. Create equipment_catalog table
CREATE TABLE IF NOT EXISTS public.equipment_catalog (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    item_type TEXT NOT NULL,
    minimum_required INTEGER NOT NULL DEFAULT 0
);

-- 2. Create learning_content table
CREATE TABLE IF NOT EXISTS public.learning_content (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'PDF',
    category TEXT NOT NULL,
    url TEXT NOT NULL
);

-- 3. Enable RLS
ALTER TABLE public.equipment_catalog ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_content ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies (Allow all authenticated users to read catalogs)
DROP POLICY IF EXISTS "Allow authenticated read" ON public.equipment_catalog;
CREATE POLICY "Allow authenticated read" ON public.equipment_catalog FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow authenticated read" ON public.learning_content;
CREATE POLICY "Allow authenticated read" ON public.learning_content FOR SELECT TO authenticated USING (true);

-- 5. Seed Equipment Catalog (Idempotent using TRUNCATE or ON CONFLICT, here we use TRUNCATE then INSERT for simplicity since it's a seed script)
TRUNCATE TABLE public.equipment_catalog;

INSERT INTO public.equipment_catalog (name, category, item_type, minimum_required) VALUES
('תחבושת אלסטית חומה רגילה 4 אינץ', 'וסט חובש', 'מתכלה', 2),
('תחבושת מיוחדת שעוצרת דימומים', 'וסט חובש', 'מתכלה', 1),
('שקיות נוזלים לעירוי (הרטמן 500 מל)', 'וסט חובש', 'מתכלה', 2),
('מים קטנים לשטיפת פצעים (סליין 10 מל)', 'וסט חובש', 'מתכלה', 4),
('כדורי אקמול רגילים (500 מג)', 'וסט חובש', 'מתכלה', 20),
('כפפות רפואיות חד פעמיות', 'וסט חובש', 'מתכלה', 20),
('מחטים למזרקים', 'וסט חובש', 'מתכלה', 2),
('מזרקי פלסטיק רגילים 3 סמק', 'וסט חובש', 'מתכלה', 6),
('משולשי בד לחבישה וקיבוע', 'וסט חובש', 'מתכלה', 4),
('גלילי פלסטר רפואי דביק', 'וסט חובש', 'מתכלה', 5),
('פדים סטריליים מבד גזה', 'וסט חובש', 'מתכלה', 11),
('מחטי וונפלון פלסטיק לעירוי', 'וסט חובש', 'מתכלה', 7),
('תחבושות אישיות ושדה (ירוקות)', 'וסט חובש', 'מתכלה', 9),
('תחבושת גדולה מאוד לבטן', 'וסט חובש', 'מתכלה', 1),
('גומי חוסם ורידים', 'וסט חובש', 'קבוע', 2),
('חוסמי עורקים לעצירת דימום', 'וסט חובש', 'קבוע', 4),
('מדחום למדידת חום', 'וסט חובש', 'קבוע', 2),
('פנס רפואי קטן', 'וסט חובש', 'קבוע', 1),
('מכשיר לחמצן בדם (מד סטורציה)', 'וסט חובש', 'קבוע', 1),
('מספריים רפואיים חזקים (מלע"כ)', 'וסט חובש', 'קבוע', 1),
('מחטים חלולות לנקז אוויר (AW)', 'וסט חובש', 'קבוע', 1),
('אמצעים לפתיחת נתיב אוויר עליון (נתבי אוויר)', 'וסט חובש', 'קבוע', 2),
('תחבושת אלסטית חומה רגילה 4 אינץ', 'ארגז חופל', 'מתכלה', 2),
('מזרק אפיפן', 'ארגז חופל', 'מתכלה', 1),
('כדורי אופטלגין', 'ארגז חופל', 'מתכלה', 50),
('כדורים נגד צרבת', 'ארגז חופל', 'מתכלה', 30),
('מחטים למזרקים', 'ארגז חופל', 'מתכלה', 10),
('מקלוני עץ ארוכים עם צמר גפן', 'ארגז חופל', 'מתכלה', 100),
('משחה לשפשפות/גירויים', 'ארגז חופל', 'מתכלה', 5),
('משחה אנטיביוטית (פיוסידם)', 'ארגז חופל', 'מתכלה', 10),
('פדים או משחה של אלכוהול לחיטוי', 'ארגז חופל', 'מתכלה', 9),
('בקבוקוני פולידין וסביעור לחיטוי', 'ארגז חופל', 'מתכלה', 220),
('בקבוקוני חומר חיטוי נוזלי (כלורקסידין)', 'ארגז חופל', 'מתכלה', 48),
('גליל פלסטר דביק', 'ארגז חופל', 'מתכלה', 1),
('פלסטרים קטנים לפצעים', 'ארגז חופל', 'מתכלה', 100),
('פדים סטריליים מבד גזה', 'ארגז חופל', 'מתכלה', 30),
('שקיות צמר גפן גדולות', 'ארגז חופל', 'מתכלה', 2),
('כדורי אימודיום', 'ארגז חופל', 'מתכלה', 200),
('משחת זובירקס', 'ארגז חופל', 'מתכלה', 2),
('משחה לפטריות', 'ארגז חופל', 'מתכלה', 1),
('ספריי תכשיר נגד יתושים', 'ארגז חופל', 'מתכלה', 1),
('תחבושות אישיות לחבישה', 'ארגז חופל', 'מתכלה', 32),
('כדורי אקמול רגילים (500 מג)', 'ארגז חופל', 'מתכלה', 10),
('ארגז עזרה ראשונה (הקופסה עצמה)', 'ארגז חופל', 'קבוע', 1),
('פנקס הפניות רופא (טופס 102)', 'ארגז חופל', 'קבוע', 1),
('פנקס רישום במרפאה (טופס 135)', 'ארגז חופל', 'קבוע', 1),
('מדחום למדידת חום', 'ארגז חופל', 'קבוע', 4),
('מד לחץ דם ידני', 'ארגז חופל', 'קבוע', 1),
('מספרי חובשים', 'ארגז חופל', 'קבוע', 1),
('סטטוסקופ רפואי', 'ארגז חופל', 'קבוע', 2);

-- 6. Seed Learning Content
TRUNCATE TABLE public.learning_content;

INSERT INTO public.learning_content (title, type, category, url) VALUES
('יסודות מבנה הגוף', 'PDF', 'ציר אנטומיה', 'assets/learning_materials/ציר אנטומיה- יסודות מבנה הגוף.pdf'),
('מערכת הנשימה', 'PDF', 'ציר אנטומיה', 'assets/learning_materials/ציר אנטומיה - מערכת הנשימה.pdf'),
('מערכת ההובלה', 'PDF', 'ציר אנטומיה', 'assets/learning_materials/ציר אנטומיה - מערכת ההובלה.pdf'),
('מערכת העצבים', 'PDF', 'ציר אנטומיה', 'assets/learning_materials/ציר אנטומיה - מערכת העצבים.pdf'),
('עצירת דימומים', 'PDF', 'ציר טראומה', 'assets/learning_materials/ציר טראומה - עצירת דימומים.pdf'),
('קינימטיקה בטראומה', 'PDF', 'ציר טראומה', 'assets/learning_materials/קינימטיקה בטראומה.pdf'),
('פגיעות שונות', 'PDF', 'ציר טראומה', 'assets/learning_materials/ציר טראומה - פגיעות שונות.pdf'),
('תגובת קרב ודחק', 'PDF', 'ציר טראומה', 'assets/learning_materials/תגובת קרב & דחק.pdf'),
('אוכלוסיות מיוחדות', 'PDF', 'ציר טראומה', 'assets/learning_materials/אוכלוסיות מיוחדות.pdf'),
('שמירה על עמש"צ', 'PDF', 'ציר טראומה', 'assets/learning_materials/ציר טראומה - שמירה על עמוד שדרה צווארי.pdf'),
('פרוצדורות', 'PDF', 'ציר טראומה', 'assets/learning_materials/פרוצדרות - נקז חזה, זונדה, גישה ורידית חלופית.pdf'),
('פגיעות AR', 'PDF', 'ציר טראומה', 'assets/learning_materials/ציר טראומה - שלבים AR.pdf'),
('פגיעות הלם', 'PDF', 'ציר טראומה', 'assets/learning_materials/פגיעות הלם.pdf'),
('סקר שניוני והטיפול המתמשך', 'PDF', 'ציר טראומה', 'assets/learning_materials/ציר טראומה- סקר שניוני וטיפול מתמשך.pdf'),
('טיפול בכאב', 'PDF', 'ציר טראומה', 'assets/learning_materials/טיפול בכאב.pdf'),
('גישה ורידית', 'PDF', 'ציר טראומה', 'assets/learning_materials/ציר טראומה - גישה ורידית.pdf'),
('אירוע רב נפגעים', 'PDF', 'ציר טראומה', 'assets/learning_materials/ציר טראומה - אירוע רב נפגעים.pdf'),
('חבישות וקיבועים', 'PDF', 'ציר טראומה', 'assets/learning_materials/חבישות וקיבועים.pdf'),
('מבוא לטראומה', 'PDF', 'ציר טראומה', 'assets/learning_materials/ציר טראומה - מבוא.pdf'),
('שלבים XC', 'PDF', 'ציר טראומה', 'assets/learning_materials/ציר טראומה - שלבים XC.pdf'),
('הערכה וניהול נתיב אוויר', 'PDF', 'ציר טראומה', 'assets/learning_materials/הערכה וניהול נתיב אוויר.pdf'),
('פגיעות אקלים חם', 'PDF', 'ציר טראומה', 'assets/learning_materials/פגיעות אקלים חם.pdf'),
('פגיעות אקלים קר', 'PDF', 'ציר טראומה', 'assets/learning_materials/פגיעות אקלים קר.pdf'),
('שלבים ARE', 'PDF', 'ציר טראומה', 'assets/learning_materials/ציר טראומה - שלבים ARE.pdf'),
('החייאת בקרת נזקים בשדה', 'PDF', 'ציר טראומה', 'assets/learning_materials/ציר טראומה - החייאת בקרת נזקים בשדה.pdf'),
('סמכת טיפול בפצוע - XCARE', 'PDF', 'ציר טראומה', 'assets/learning_materials/סכמת XCARE.pdf'),
('עבודה עם מחצי"ם', 'PDF', 'ציר טראומה', 'assets/learning_materials/מצגת - עבודה עם מחצים - אוקטובר 2023 2.pptx'),
('החייאת מבוגר', 'PDF', 'ציר החייאה', 'assets/learning_materials/החייאת מבוגר.pdf'),
('החייאת ילדים ותינוקות', 'PDF', 'ציר החייאה', 'assets/learning_materials/החייאת ילדים ותינוקות.pdf'),
('סילוק גוף זר', 'PDF', 'ציר החייאה', 'assets/learning_materials/חנק - סילוק גוף זר.pdf'),
('מכשירי החייאה', 'PDF', 'ציר החייאה', 'assets/learning_materials/מכשירי החייאה.pdf'),
('חשיפה לדם', 'PDF', 'ציר שגרה', 'assets/learning_materials/חשיפה לדם.pdf'),
('גישה ורידית ושאיבות דם', 'PDF', 'ציר שגרה', 'assets/learning_materials/גישה ורידית ושאיבות דם מהוריד.pdf');

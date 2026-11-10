import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';
import 'package:chopel_app/theme/components/hopal_empty_state.dart';
import 'package:chopel_app/theme/components/hopal_search_bar.dart';
import 'package:chopel_app/theme/components/hopal_segmented_control.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';

class Medication {
  final String id;
  final String name;
  final String activeIngredient;
  final String category;
  final String indications;
  final String contraindications;
  final String adultDose;
  final String sideEffects;
  final String fieldTip;
  final String administrationRoute;
  final int standardSingleDoseMg;
  final int unitStrengthMg;
  final int maxDailyMg;
  final int dosingIntervalHours;
  final bool isG6pdContraindicated;
  final bool isNsaidContraindicated;
  final bool isAsthmaContraindicated;
  final bool isUlcerContraindicated;
  final bool requiresDoctorAuth;

  const Medication({
    required this.id,
    required this.name,
    required this.activeIngredient,
    required this.category,
    required this.indications,
    required this.contraindications,
    required this.adultDose,
    required this.sideEffects,
    required this.fieldTip,
    required this.administrationRoute,
    required this.standardSingleDoseMg,
    required this.unitStrengthMg,
    required this.maxDailyMg,
    required this.dosingIntervalHours,
    this.isG6pdContraindicated = false,
    this.isNsaidContraindicated = false,
    this.isAsthmaContraindicated = false,
    this.isUlcerContraindicated = false,
    this.requiresDoctorAuth = false,
  });
}

class MedicationGuideScreen extends StatefulWidget {
  final String? initialMedicationId;

  const MedicationGuideScreen({super.key, this.initialMedicationId});

  static const List<Medication> medications = [
    Medication(
      id: 'acamol',
      name: 'אקמול (Acamol)',
      activeIngredient: 'Paracetamol',
      category: 'שיכוך כאב והורדת חום',
      indications: 'שיכוך כאב קל עד בינוני, הורדת חום, כאבי ראש ומחלות שגרתיות.',
      contraindications: 'רגישות ידועה לפראצטמול, אי ספיקת כבד קשה.',
      adultDose: '500-1,000 מ"ג (1-2 כדורים) כל 4-6 שעות. מקסימום 4 גרם (8 כדורים) ביממה.',
      sideEffects: 'נדיר במינון טיפולי. במינון יתר: רעילות כבדית מסכנת חיים.',
      fieldTip: 'קו ראשון לחום וכאב קל בשטח. בטוח בחולי G6PD ואינו מגרה את רירית הקיבה.',
      administrationRoute: 'פומי (בבליעה)',
      standardSingleDoseMg: 1000,
      unitStrengthMg: 500,
      maxDailyMg: 4000,
      dosingIntervalHours: 6,
    ),
    Medication(
      id: 'optalgin',
      name: 'אופטלגין (Optalgin)',
      activeIngredient: 'Dipyrone / Metamizole',
      category: 'שיכוך כאב והורדת חום',
      indications: 'כאב בינוני עד חזק (כאב ויסרלי, עוויתי, כאבי שיניים), חום שלא מגיב לאקמול.',
      contraindications: 'רגישות ידועה, חסר ב-G6PD (רגישות לפול), מחלות מח עצם, הריון/הנקה.',
      adultDose: '500-1,000 מ"ג (1-2 כדורים או 25-50 טיפות) כל 6-8 שעות. מקסימום 4 גרם ביממה.',
      sideEffects: 'נדיר אך מסוכן: אגרנולוציטוזיס (פגיעה במח העצם), ירידת לחץ דם במתן ורידי.',
      fieldTip: 'חובה לוודא היעדר חסר G6PD לפני מתן! יעיל מאוד לכאבי בטן עוויתיים וכאבי שיניים עזים.',
      administrationRoute: 'פומי / טיפות / ורידי',
      standardSingleDoseMg: 1000,
      unitStrengthMg: 500,
      maxDailyMg: 4000,
      dosingIntervalHours: 6,
      isG6pdContraindicated: true,
    ),
    Medication(
      id: 'nurofen',
      name: 'נורופן / איבופרופן / אדוויל',
      activeIngredient: 'Ibuprofen (NSAID)',
      category: 'שיכוך כאב והורדת חום',
      indications: 'כאבי שרירים ושלד, נקעים, דלקות, כאבי גב, שיכוך כאב ונוגד דלקת.',
      contraindications: 'כיב קיבה/תריסריון (אולקוס), אסתמה רגישה ל-NSAID, התייבשות משמעותית, דימום פעיל.',
      adultDose: '400 מ"ג (2 כדורים של 200 או 1 של 400) כל 8 שעות. חובה לאחר אוכל. מקסימום 1,200-2,400 מ"ג ביממה.',
      sideEffects: 'כאבי בטן, צרבת, פגיעה כלייתית בהתייבשות, החמרת דימום.',
      fieldTip: 'חובה לתת עם מזון והרבה מים! לא לתת לחייל מיובש (חשש לפגיעה כלייתית).',
      administrationRoute: 'פומי (לאחר אוכל)',
      standardSingleDoseMg: 400,
      unitStrengthMg: 200,
      maxDailyMg: 1200,
      dosingIntervalHours: 8,
      isNsaidContraindicated: true,
      isAsthmaContraindicated: true,
      isUlcerContraindicated: true,
    ),
    Medication(
      id: 'voltaren',
      name: 'וולטרן / דיקלופנק (Voltaren)',
      activeIngredient: 'Diclofenac (NSAID)',
      category: 'שיכוך כאב והורדת חום',
      indications: 'דלקות שריר ושלד, נקעים, חבלות סגורות ומפרקים (ג\'ל מקומי או כדורים באישור רופא).',
      contraindications: 'רגישות ל-NSAIDs, כיב קיבה פעיל, פצע פתוח (לג\'ל מקומי), התייבשות.',
      adultDose: 'ג\'ל מקומי: מריחה דקה 2-3 פעמים ביום. פומי (50-100 מ"ג) באישור רופא בלבד.',
      sideEffects: 'גירוי עורי מקומי (ג\'ל), צרבות וכאבי בטן (פומי).',
      fieldTip: 'עדיף למרוח ג\'ל מקומי על נקע/מכה סגורה לפני מתן כדורים כדי להימנע מתופעות לוואי בקיבה.',
      administrationRoute: 'מקומי (עור) / פומי',
      standardSingleDoseMg: 50,
      unitStrengthMg: 50,
      maxDailyMg: 150,
      dosingIntervalHours: 8,
      isNsaidContraindicated: true,
      isAsthmaContraindicated: true,
      isUlcerContraindicated: true,
    ),
    Medication(
      id: 'tramadex',
      name: 'טרמדקס / טרמדול (Tramadol)',
      activeIngredient: 'Tramadol Hydrochloride',
      category: 'שיכוך כאב והורדת חום',
      indications: 'כאב בינוני עד חמור שלא מגיב לאקמול ו-NSAIDs, חבלות משמעותיות (בסמכות רופא).',
      contraindications: 'פגיעות ראש וירידה בהכרה, דיכוי נשימתי, אפילפסיה/פרכוסים, שימוש באלכוהול/סמי הרגעה.',
      adultDose: '50-100 מ"ג (1-2 טבליות / טיפות) כל 6-8 שעות. מקסימום 400 מ"ג ביממה.',
      sideEffects: 'סחרחורת, בחילה, ישנוניות, עצירות, דיכוי נשימתי במינון יתר.',
      fieldTip: 'תרופה אופיואידית חלשה. אסור לתת לחייל שנוהג או מפעיל נשק כבד. דורש השגחה ומעקב נשימתי.',
      administrationRoute: 'פומי / טיפות',
      standardSingleDoseMg: 50,
      unitStrengthMg: 50,
      maxDailyMg: 400,
      dosingIntervalHours: 6,
      requiresDoctorAuth: true,
    ),
    Medication(
      id: 'actiq',
      name: 'אקטיק / סוכריית פנטניל (Actiq)',
      activeIngredient: 'Fentanyl Citrate 800mcg',
      category: 'חירום והחייאה',
      indications: 'שיכוך כאב חמור בפצועי טראומה וקרב במודעות מלאה ללא חבלת ראש וללא דיכוי נשימתי.',
      contraindications: 'פצוע מחוסר הכרה או מעורפל, הלם עמוק, דיכוי נשימתי, חבלת ראש סגורה/קשה.',
      adultDose: 'סוכרייה של 800 מק"ג להדבקה ללחי ומציצה איטית (מעל 15 דקות). אסור ללעוס או לבלוע שלם!',
      sideEffects: 'דיכוי נשימתי, ירידת לחץ דם, בחילה, טשטוש עמוק.',
      fieldTip: 'פרוטוקול שטח: לחבר את מקל הסוכרייה לאצבע הפצוע עם סקוטש/סרט הדבקה — אם הפצוע מטשטש ידו נופלת והסוכרייה יוצאת מפיו!',
      administrationRoute: 'טרנס-מוקוזלי (רירית הלחי)',
      standardSingleDoseMg: 1,
      unitStrengthMg: 1,
      maxDailyMg: 2,
      dosingIntervalHours: 4,
      requiresDoctorAuth: true,
    ),
    Medication(
      id: 'txa',
      name: 'הקסאקפרון – TXA (פרוטוקול טראומה)',
      activeIngredient: 'Tranexamic Acid',
      category: 'חירום והחייאה',
      indications: 'דימום פנימי או חיצוני חמור, חשד להלם היפו-וולמי בטראומה תוך עד 3 שעות מרגע הפציעה.',
      contraindications: 'חלפו יותר מ-3 שעות מרגע הפציעה, אירוע תסחיפי/קרישתי פעיל.',
      adultDose: '1 גרם בעירוי איטי (במשך 10 דקות ב-100 מ"ל סליין), ולאחר מכן 1 גרם נוסף בעירוי המשכי לפי פרוטוקול.',
      sideEffects: 'ירידת לחץ דם במתן ורידי מהיר מדי, בחילה, סחרחורת.',
      fieldTip: 'זמן הוא קריטי! יש לתת מוקדם ככל האפשר בשטח. לא להזריק בדחיפה מהירה (IV Push) מחשש לצניחת ל"ד.',
      administrationRoute: 'תוך-ורידי (IV איטי)',
      standardSingleDoseMg: 1000,
      unitStrengthMg: 1000,
      maxDailyMg: 2000,
      dosingIntervalHours: 8,
      requiresDoctorAuth: true,
    ),
    Medication(
      id: 'epipen',
      name: 'אפיפן (EpiPen)',
      activeIngredient: 'Epinephrine (Adrenaline)',
      category: 'חירום והחייאה',
      indications: 'תגובה אלרגית מסכנת חיים (אנפילקסיס): קוצר נשימה, נפיחות שפתיים/לשון, צפצופים, ירידת ל"ד.',
      contraindications: 'אין התוויות נגד מוחלטות באנפילקסיס מסכן חיים!',
      adultDose: '0.3 מ"ג (מזרק צהוב אוטומטי למבוגר) בהזרקה לשריר הירך החיצוני (IM). ניתן לחזור אחרי 5-15 דק\' בהיעדר שיפור.',
      sideEffects: 'דפיקות לב מהירות (טכיקרדיה), רעד, פלפיטציות, חיוורון.',
      fieldTip: 'להחזיק את המזרק 10 שניות צמוד לירך (ניתן להזריק דרך מכנסי מדים), לעסות את המקום ולהזניק פינוי דחוף.',
      administrationRoute: 'תוך-שרירי (IM ירך)',
      standardSingleDoseMg: 1,
      unitStrengthMg: 1,
      maxDailyMg: 2,
      dosingIntervalHours: 1,
    ),
    Medication(
      id: 'imodium',
      name: 'אימודיום (Imodium)',
      activeIngredient: 'Loperamide',
      category: 'מערכת העיכול',
      indications: 'שלשול חריף לא זיהומי (ללא חום וללא דם/ריר ביציאה).',
      contraindications: 'שלשול דמי, חום גבוה (חשד לדיזנטריה חיידקית פולשנית), חשד לחסימת מעיים.',
      adultDose: 'מנה ראשונה: 2 כדורים (4 מ"ג) מיד. לאחר מכן כדור אחד (2 מ"ג) אחרי כל יציאה שלשולית. מקסימום 8-16 מ"ג ביממה.',
      sideEffects: 'עצירות, כאבי בטן עוויתיים, בחילות, יובש בפה.',
      fieldTip: 'חובה לשלב עם החזרת נוזלים ומלחים (ORS)! אם יש חום או דם — אסור לתת אימודיום, יש לפנות לרופא.',
      administrationRoute: 'פומי (בבליעה)',
      standardSingleDoseMg: 4,
      unitStrengthMg: 2,
      maxDailyMg: 16,
      dosingIntervalHours: 4,
    ),
    Medication(
      id: 'pramin',
      name: 'פראמין (Pramin)',
      activeIngredient: 'Metoclopramide',
      category: 'מערכת העיכול',
      indications: 'בחילות והקאות על רקע גסטרואנטריטיס, מיגרנה או תופעות לוואי של תרופות.',
      contraindications: 'חשד לחסימת מעיים או דימום במערכת העיכול, אפילפסיה, פאוכרומוציטומה.',
      adultDose: '10 מ"ג (כדור אחד) עד 3 פעמים ביום לפני אוכל. מקסימום 30 מ"ג ביממה.',
      sideEffects: 'עייפות, ישנוניות, תופעות אקסטרה-פירמידליות (אי-שקט מוטורי/נוקשות שרירים נדירה).',
      fieldTip: 'יעיל מאוד בהקאות המונעות שתייה. אם מופיע אי-שקט שרירי מוזר — להפסיק מיד.',
      administrationRoute: 'פומי / תוך-שרירי (IM)',
      standardSingleDoseMg: 10,
      unitStrengthMg: 10,
      maxDailyMg: 30,
      dosingIntervalHours: 8,
    ),
    Medication(
      id: 'zofran',
      name: 'זופרן (Zofran)',
      activeIngredient: 'Ondansetron',
      category: 'מערכת העיכול',
      indications: 'בחילות והקאות קשות שלא מגיבות לפראמין (באישור רופא).',
      contraindications: 'רגישות לאונדנסטרון, הארכת מקטע QT ב-ECG.',
      adultDose: '4-8 מ"ג (טבליה מתמוססת על הלשון ODT או במתן ורידי איטי) כל 8 שעות.',
      sideEffects: 'כאב ראש קל, עצירות, תחושת חום.',
      fieldTip: 'הטבליה המסיסה מצוינת לשטח כי אינה דורשת בליעת מים כשהחייל מקיא.',
      administrationRoute: 'תת-לשוני (מסיס) / ורידי',
      standardSingleDoseMg: 4,
      unitStrengthMg: 4,
      maxDailyMg: 16,
      dosingIntervalHours: 8,
      requiresDoctorAuth: true,
    ),
    Medication(
      id: 'ors',
      name: 'שקיות מלחים (ORS)',
      activeIngredient: 'Oral Rehydration Salts',
      category: 'מערכת העיכול',
      indications: 'התייבשות קלה עד בינונית, שלשולים מרובים, מאמץ ממושך בחום עומס כבד.',
      contraindications: 'פצוע מחוסר הכרה, הקאות בלתי נשלטות, חסימת מעיים (דורש עירוי IV).',
      adultDose: 'שקית אחת מומסת ב-1 ליטר מים ראויים לשתייה. שתייה בלגימות איטיות קבועות.',
      sideEffects: 'בחילות קלות אם שותים מהר מדי.',
      fieldTip: 'עדיף בהרבה על שתיית מים רגילים בשלשולים כי הוא מחזיר נתרן ואשלגן ומונע התכווצויות שרירים והיפונתרמיה.',
      administrationRoute: 'פומי (שתייה איטית)',
      standardSingleDoseMg: 1,
      unitStrengthMg: 1,
      maxDailyMg: 4,
      dosingIntervalHours: 2,
    ),
    Medication(
      id: 'ventolin',
      name: 'ונטולין / סלבוטמול (Ventolin)',
      activeIngredient: 'Salbutamol Inhaler',
      category: 'נשימה ואלרגיה',
      indications: 'התקף קוצר נשימה, אסתמה, ברונכוספאזם, צפצופים בריאות לאחר שאיפת אבק/עשן.',
      contraindications: 'רגישות ידועה לסלבוטמול (זהירות בטכיקרדיה קשה).',
      adultDose: '1-2 שאיפות (Puffs) בהמתנה של דקה בין שאיפה לשאיפה. ניתן לחזור כל 20 דק\' לפי הצורך.',
      sideEffects: 'דפיקות לב מואצות (טכיקרדיה), רעד בידיים, חוסר שקט.',
      fieldTip: 'להנחות את החייל לנשוף עד תום, להצמיד פייה, לשאוף עמוק ולהחזיק נשימה 10 שניות.',
      administrationRoute: 'שאיפה (משאף)',
      standardSingleDoseMg: 2,
      unitStrengthMg: 1,
      maxDailyMg: 8,
      dosingIntervalHours: 4,
    ),
    Medication(
      id: 'loratadine',
      name: 'לורטדין (Loratadine)',
      activeIngredient: 'Loratadine (Antihistamine)',
      category: 'נשימה ואלרגיה',
      indications: 'תגובות אלרגיות קלות, פריחה, גרד, אורטיקריה, נזלת אלרגית, עקיצות.',
      contraindications: 'רגישות לחומר הפעיל (בקוצר נשימה או אנפילקסיס — אפיפן מיידי!).',
      adultDose: '10 מ"ג (כדור אחד) פעם אחת ביממה.',
      sideEffects: 'יובש קל בפה, נמנום מזערי בלבד (דור שני שאינו מרדים).',
      fieldTip: 'יתרון מבצעי ענק על פני אהיסטון: אינו גורם לנמנום ואינו פוגע בערנות הלוחם.',
      administrationRoute: 'פומי (פעם ביום)',
      standardSingleDoseMg: 10,
      unitStrengthMg: 10,
      maxDailyMg: 10,
      dosingIntervalHours: 24,
    ),
    Medication(
      id: 'silverol',
      name: 'סילברול (Silverol)',
      activeIngredient: 'Silver Sulfadiazine 1%',
      category: 'עור וחיטוי',
      indications: 'כוויות דרגה 2 ומעלה, מניעת זיהומי כוויות מקומיים.',
      contraindications: 'חסר ב-G6PD (רגישות לפול), רגישות ידועה לסולפה (Sulfa), הריון מתקדם.',
      adultDose: 'מריחה בשכבה בעובי כ-2-3 מ"מ על שטח הכוויה הנקי וחבישה סטרילית.',
      sideEffects: 'צריבה חולפת מקומית, שינוי צבע עור זמני.',
      fieldTip: 'אזהרת שטח קריטית: מכיל סולפה! אסור בהחלט ב-G6PD. לנקות בסליין לפני חידוש החבישה.',
      administrationRoute: 'מקומי (משחה לכוויות)',
      standardSingleDoseMg: 1,
      unitStrengthMg: 1,
      maxDailyMg: 3,
      dosingIntervalHours: 12,
      isG6pdContraindicated: true,
    ),
    Medication(
      id: 'dermacombin',
      name: 'דרמקומבין / אגיסטן (Dermacombin)',
      activeIngredient: 'Triamcinolone + Neomycin + Nystatin',
      category: 'עור וחיטוי',
      indications: 'שפשפות קשות דלקתיות ופטרייתיות, פטרת מפשעה (Tinea Cruris), פטרת כפות רגליים חיילים.',
      contraindications: 'זיהום ויראלי (הרפס), שחפת עור, פצעים פתוחים עמוקים.',
      adultDose: 'מריחה דקה ואחידה על אזור השפשפת 2-3 פעמים ביום לאחר רחיצה וייבוש מלא.',
      sideEffects: 'צריבה מקומית קלה, שימוש ממושך עלול לגרום להידקקות העור.',
      fieldTip: 'החבר הכי טוב של הלוחם בקיץ ובמסעות. להדגיש לחייל: לשמור על המקום יבש ומאוורר!',
      administrationRoute: 'מקומי (עור)',
      standardSingleDoseMg: 1,
      unitStrengthMg: 1,
      maxDailyMg: 3,
      dosingIntervalHours: 8,
    ),
    Medication(
      id: 'fucidin',
      name: 'פוסידין / בקטרובן (Fucidin / Bactroban)',
      activeIngredient: 'Fusidic Acid / Mupirocin',
      category: 'עור וחיטוי',
      indications: 'זיהומי עור חיידקיים שטחיים (אימפטיגו, פוליקוליטיס, פצעים מזוהמים קלים).',
      contraindications: 'רגישות ידועה לחומר הפעיל.',
      adultDose: 'מריחה דקה 2-3 פעמים ביום על הפצע הנקי עם חבישה נושמת.',
      sideEffects: 'גירוי עורי קל.',
      fieldTip: 'לשטוף בסבון ומים או סליין לפני מריחת המשחה כדי להסיר גלדים ולהבטיח חדירה טובה.',
      administrationRoute: 'מקומי (עור)',
      standardSingleDoseMg: 1,
      unitStrengthMg: 1,
      maxDailyMg: 3,
      dosingIntervalHours: 8,
    ),
  ];

  @override
  State<MedicationGuideScreen> createState() => _MedicationGuideScreenState();
}

class _MedicationGuideScreenState extends State<MedicationGuideScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentTab = 0; // 0 = Guide, 1 = Calculator
  String _searchQuery = '';
  String _selectedCategory = 'הכל';

  // Calculator State
  late Medication _calcSelectedMed;
  double _soldierWeightKg = 70.0;
  bool _hasG6pd = false;
  bool _hasAsthma = false;
  bool _hasUlcerOrNsaidAllergy = false;
  bool _isDehydrated = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMedicationId != null) {
      final found = MedicationGuideScreen.medications.where((m) => m.id == widget.initialMedicationId).firstOrNull;
      _calcSelectedMed = found ?? MedicationGuideScreen.medications.first;
      _currentTab = 1; // Open calculator directly
    } else {
      _calcSelectedMed = MedicationGuideScreen.medications.first;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _switchToCalculator(Medication med) {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
    setState(() {
      _calcSelectedMed = med;
      _currentTab = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('תרופות שטח ומחשבון מינונים', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowRight, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing8),
            child: HopalSegmentedControl(
              segments: const ['מדריך תרופות שטח', 'מחשבון מינונים ובטיחות'],
              selectedIndex: _currentTab,
              onValueChanged: (index) {
                try {
                  HapticFeedback.selectionClick();
                } catch (_) {}
                setState(() => _currentTab = index);
              },
            ),
          ),
          Expanded(
            child: _currentTab == 0 ? _buildGuideTab() : _buildCalculatorTab(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: GUIDE TAB
  // ==========================================
  Widget _buildGuideTab() {
    final allCategories = ['הכל', ...MedicationGuideScreen.medications.map((m) => m.category).toSet()];

    final filtered = MedicationGuideScreen.medications.where((m) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          m.name.toLowerCase().contains(q) ||
          m.activeIngredient.toLowerCase().contains(q) ||
          m.indications.toLowerCase().contains(q) ||
          m.contraindications.toLowerCase().contains(q) ||
          m.fieldTip.toLowerCase().contains(q);
      final matchesCat = _selectedCategory == 'הכל' || m.category == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, AppTheme.spacing8, AppTheme.spacing16, AppTheme.spacing8),
            child: HopalSearchBar(
              controller: _searchController,
              placeholder: 'חפש תרופה, חומר פעיל, G6PD, כאב, כוויות...',
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing8),
            child: Row(
              children: allCategories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(left: AppTheme.spacing8),
                  child: ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? AppTheme.onPrimaryGreen : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    checkmarkColor: AppTheme.onPrimaryGreen,
                    onSelected: (selected) {
                      if (selected) {
                        try {
                          HapticFeedback.selectionClick();
                        } catch (_) {}
                        setState(() => _selectedCategory = cat);
                      }
                    },
                    backgroundColor: AppTheme.backgroundSecondary,
                    selectedColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? AppTheme.primaryGreen : AppTheme.borderSubtle),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (filtered.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: AppTheme.spacing48),
              child: HopalEmptyState(
                icon: LucideIcons.pill,
                title: 'לא נמצאה תרופה תואמת',
                subtitle: 'נסה לחפש בשם מסחרי, חומר פעיל או תלונה אחרת.',
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final med = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacing16),
                    child: _buildMedicationCard(med),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildMedicationCard(Medication med) {
    return HopalCard(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: AppTheme.radiusMd,
                ),
                child: Icon(LucideIcons.pill, color: AppTheme.primaryGreen, size: 22),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${med.activeIngredient} • ${med.administrationRoute}',
                      style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  side: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(LucideIcons.calculator, size: 14),
                label: const Text('מחשבון', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () => _switchToCalculator(med),
              ),
            ],
          ),
          if (med.isG6pdContraindicated || med.requiresDoctorAuth) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (med.isG6pdContraindicated)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.criticalRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.criticalRed.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.alertTriangle, size: 12, color: AppTheme.criticalRed),
                        const SizedBox(width: 4),
                        Text(
                          'אסור בחסר G6PD (רגישות לפול)',
                          style: TextStyle(fontSize: 11, color: AppTheme.criticalRed, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                if (med.requiresDoctorAuth)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.warningAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.warningAmber.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.stethoscope, size: 12, color: AppTheme.warningAmber),
                        const SizedBox(width: 4),
                        Text(
                          'בסמכות רופא / נוהל גדודי',
                          style: TextStyle(fontSize: 11, color: AppTheme.warningAmber, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppTheme.spacing12),
            child: Divider(height: 1),
          ),
          _buildInfoRow('התוויות', med.indications, LucideIcons.checkCircle2, AppTheme.successGreen),
          const SizedBox(height: AppTheme.spacing8),
          _buildInfoRow('מינון שטח סטנדרטי', med.adultDose, LucideIcons.syringe, AppTheme.primaryGreen),
          const SizedBox(height: AppTheme.spacing8),
          _buildInfoRow('התוויות נגד ואזהרות', med.contraindications, LucideIcons.xCircle, AppTheme.criticalRed),
          const SizedBox(height: AppTheme.spacing8),
          _buildInfoRow('דגש שטח לחובש', med.fieldTip, LucideIcons.shieldAlert, AppTheme.infoBlue),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String content, IconData icon, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: AppTheme.spacing8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5, height: 1.45),
              children: [
                TextSpan(text: '$title: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                TextSpan(text: content),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: INTERACTIVE DOSAGE & SAFETY CALCULATOR
  // ==========================================
  Widget _buildCalculatorTab() {
    final med = _calcSelectedMed;

    // Safety check evaluation
    String? contraindicationReason;
    String? warningReason;

    if (med.isG6pdContraindicated && _hasG6pd) {
      contraindicationReason = 'התוויית נגד מוחלטת: החייל מוגדר כבעל חסר G6PD (רגישות לפול). מתן התרופה עלול לגרום להמוליזה חמורה ולסכנת חיים!';
    } else if (med.isNsaidContraindicated && _hasUlcerOrNsaidAllergy) {
      contraindicationReason = 'התוויית נגד: החייל מוגדר עם רגישות ל-NSAID או כיב קיבה/דימום פעיל. סכנת פגיעה קשה ברירית הקיבה והחמרת דימום.';
    } else if (med.isAsthmaContraindicated && _hasAsthma) {
      warningReason = 'זהירות גבוהה: החייל אסמטי. תרופות ממשפחת ה-NSAID עלולות לעורר התקף ברונכוספאזם חריף (Aspirin-exacerbated respiratory disease). עדיף לתת אקמול!';
    } else if (med.isNsaidContraindicated && _isDehydrated) {
      warningReason = 'אזהרת התייבשות: מתן NSAID לחייל מיובש מעלה משמעותית סיכון לאי-ספיקת כליות חריפה. חובה להחזיר נוזלים לפני שקילת מתן!';
    }

    final isBlocked = contraindicationReason != null;

    // Dose calculation
    final tabletsPerDose = (med.standardSingleDoseMg / med.unitStrengthMg).toStringAsFixed(0);
    final maxTabletsPerDay = (med.maxDailyMg / med.unitStrengthMg).toStringAsFixed(0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Select Medication Dropdown
          Text('בחר תרופה לחישוב ובדיקת בטיחות:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 15)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary,
              borderRadius: AppTheme.radiusMd,
              border: Border.all(color: AppTheme.borderStrong),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Medication>(
                value: med,
                isExpanded: true,
                dropdownColor: AppTheme.backgroundSecondary,
                icon: Icon(LucideIcons.chevronDown, color: AppTheme.primaryGreen),
                items: MedicationGuideScreen.medications.map((m) {
                  return DropdownMenuItem<Medication>(
                    value: m,
                    child: Text(
                      m.name,
                      style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14.5),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    try {
                      HapticFeedback.selectionClick();
                    } catch (_) {}
                    setState(() => _calcSelectedMed = val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),

          // Soldier Weight Presets
          Text('משקל החייל (ק"ג): ${_soldierWeightKg.round()} ק"ג', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [60.0, 70.0, 80.0, 90.0, 100.0].map((w) {
              final isSel = (_soldierWeightKg - w).abs() < 1;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSel ? AppTheme.primaryGreen.withValues(alpha: 0.15) : AppTheme.backgroundSecondary,
                      side: BorderSide(color: isSel ? AppTheme.primaryGreen : AppTheme.borderSubtle),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      try {
                        HapticFeedback.selectionClick();
                      } catch (_) {}
                      setState(() => _soldierWeightKg = w);
                    },
                    child: Text(
                      '${w.round()}',
                      style: TextStyle(
                        color: isSel ? AppTheme.primaryGreen : AppTheme.textSecondary,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          Slider(
            value: _soldierWeightKg,
            min: 45.0,
            max: 130.0,
            divisions: 85,
            activeColor: AppTheme.primaryGreen,
            inactiveColor: AppTheme.borderSubtle,
            label: '${_soldierWeightKg.round()} ק"ג',
            onChanged: (val) => setState(() => _soldierWeightKg = val),
          ),
          const SizedBox(height: AppTheme.spacing16),

          // Safety & Red Flags Toggles
          Text('בדיקת בטיחות קלינית והצלבת רגישויות:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 15)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary,
              borderRadius: AppTheme.radiusMd,
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              children: [
                _buildCheckRow('רגישות ל-G6PD (רגישות לפול)', _hasG6pd, (val) => setState(() => _hasG6pd = val)),
                const Divider(height: 12),
                _buildCheckRow('אסתמה פעילה / מחלת ריאות', _hasAsthma, (val) => setState(() => _hasAsthma = val)),
                const Divider(height: 12),
                _buildCheckRow('רגישות ל-NSAID / כיב קיבה או דימום', _hasUlcerOrNsaidAllergy, (val) => setState(() => _hasUlcerOrNsaidAllergy = val)),
                const Divider(height: 12),
                _buildCheckRow('התייבשות משמעותית / חום קיצוני', _isDehydrated, (val) => setState(() => _isDehydrated = val)),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),

          // Calculation Result Card
          Text('תוצאת החישוב והוראות מתן בשטח:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 15)),
          const SizedBox(height: 8),
          HopalCard(
            borderColor: isBlocked
                ? AppTheme.criticalRed
                : (warningReason != null ? AppTheme.warningAmber : AppTheme.primaryGreen),
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Alert Banner
                if (isBlocked)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spacing12),
                    decoration: BoxDecoration(
                      color: AppTheme.criticalRed.withValues(alpha: 0.15),
                      borderRadius: AppTheme.radiusMd,
                      border: Border.all(color: AppTheme.criticalRed),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.shieldX, color: AppTheme.criticalRed, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            contraindicationReason!,
                            style: TextStyle(color: AppTheme.criticalRed, fontWeight: FontWeight.bold, fontSize: 13.5, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (warningReason != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spacing12),
                    decoration: BoxDecoration(
                      color: AppTheme.warningAmber.withValues(alpha: 0.15),
                      borderRadius: AppTheme.radiusMd,
                      border: Border.all(color: AppTheme.warningAmber),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.alertTriangle, color: AppTheme.warningAmber, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            warningReason,
                            style: TextStyle(color: AppTheme.warningAmber, fontWeight: FontWeight.bold, fontSize: 13.5, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                      borderRadius: AppTheme.radiusMd,
                      border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.checkCircle2, color: AppTheme.primaryGreen, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'תקין למתן לפי פרוטוקול שטח',
                          style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: AppTheme.spacing16),

                // Dose metrics row
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricBox(
                        title: 'מנה בודדת',
                        value: '${med.standardSingleDoseMg} מ"ג',
                        subtitle: '$tabletsPerDose כדורים (${med.unitStrengthMg} מ"ג ליחידה)',
                        color: isBlocked ? AppTheme.criticalRed : AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricBox(
                        title: 'מרווח זמן',
                        value: 'כל ${med.dosingIntervalHours} שעות',
                        subtitle: 'דרך מתן: ${med.administrationRoute}',
                        color: AppTheme.infoBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildMetricBox(
                  title: 'תקרת מינון מקסימלית ליממה (24 שעות)',
                  value: 'עד ${med.maxDailyMg} מ"ג ביממה ($maxTabletsPerDay כדורים סה"כ)',
                  subtitle: 'אין לחרוג מתקרה זו מחשש להרעלה ורעילות איברים',
                  color: AppTheme.warningAmber,
                ),

                const SizedBox(height: AppTheme.spacing12),
                Text(
                  'דגש שטח: ${med.fieldTip}',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCheckRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppTheme.textPrimary, fontSize: 13.5)),
        Switch.adaptive(
          value: value,
          activeColor: AppTheme.primaryGreen,
          onChanged: (newVal) {
            try {
              HapticFeedback.selectionClick();
            } catch (_) {}
            onChanged(newVal);
          },
        ),
      ],
    );
  }

  Widget _buildMetricBox({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppTheme.radiusMd,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

import 'dart:async';

class MedicalCopilotService {
  /// Analyzes the medical complaint and returns a simulated AI response.
  Future<Map<String, dynamic>> analyzeSymptoms(String complaint) async {
    // Simulate network/AI delay
    await Future.delayed(const Duration(seconds: 2));

    if (complaint.isEmpty) {
      return {
        'diagnosis': 'לא סופק תיאור מספיק',
        'treatment': 'נא להזין תלונות או תגיות רלוונטיות לקבלת המלצה.',
        'redFlags': [],
        'medications': [],
      };
    }

    // Keyword based simulation for the MVP
    List<String> diagnoses = [];
    List<String> treatments = [];
    List<String> redFlags = [];
    List<String> medications = [];

    if (complaint.contains('בטן') || complaint.contains('שלשול')) {
      diagnoses.add('חשד לגסטרואנטריטיס / זיהום במערכת העיכול');
      treatments.add('• בטן/שלשולים: מנוחה, שתייה מרובה, מעקב חום.');
      redFlags.addAll(['חום מעל 38.5 לאורך זמן', 'דם בצואה', 'סימני התייבשות']);
      medications.addAll(['כדורי אימודיום', 'אקמול (500 מג)']);
    }

    if (complaint.contains('ראש') || complaint.contains('מיגרנה')) {
      diagnoses.add('כאב ראש / חשד להתייבשות');
      treatments.add('• כאב ראש: מנוחה בחדר חשוך ושקט, שתיית מים מרובה, מדידת לחץ דם.');
      redFlags.addAll(['הקאות מרובות', 'כאב ראש פתאומי ועוצמתי מאוד', 'טשטוש ראייה']);
      medications.addAll(['כדורי אופטלגין', 'כדורי אקמול']);
    }

    if (complaint.contains('פצע') || complaint.contains('דימום') || complaint.contains('שפשוף') || complaint.contains('שפשפת') || complaint.contains('שפשפות')) {
      diagnoses.add('פצע שטחי / טראומה קלה');
      treatments.add('• פצע/שפשוף: שטיפה עם סליין, חיטוי, וחבישה סטרילית.');
      redFlags.addAll(['דימום שאינו פוסק לאחר לחץ ישיר', 'סימני זיהום מקומי']);
      medications.addAll(['פדים לחיטוי', 'משחה אנטיביוטית (פיוסידם)']);
    }
    
    if (complaint.contains('חום') || complaint.contains('צינון')) {
      diagnoses.add('מחלת חום / זיהום ויראלי');
      treatments.add('• מחלת חום: מדידת מדדים, מנוחה ושתייה מרובה.');
      redFlags.addAll(['קשיי נשימה', 'חום מעל 39 שלא יורד', 'ערפול הכרה']);
      medications.addAll(['אקמול', 'אופטלגין', 'לכסניות למציצה']);
    }
    
    if (complaint.contains('גרון')) {
      diagnoses.add('דלקת גרון');
      treatments.add('• גרון: בדיקת לוע, משטח גרון במידת הצורך, שתייה מרובה.');
      redFlags.addAll(['קושי בבליעת רוק', 'קושי בנשימה', 'נפיחות חד צדדית ניכרת']);
      medications.addAll(['לכסניות מציצה', 'אנטיביוטיקה (באישור רופא)']);
    }
    
    if (complaint.contains('גב') || complaint.contains('ברכיים') || complaint.contains('ברך') || complaint.contains('שריר')) {
      diagnoses.add('כאב אורתופדי');
      treatments.add('• כאב אורתופדי: בדיקה פיזיקלית, מנוחה, קירור/חימום המקום.');
      redFlags.addAll(['חוסר תחושה/חולשה בגפיים', 'איבוד שליטה על סוגרים', 'כאב בלתי נסבל במנוחה']);
      medications.addAll(['משחת וולטרן', 'איבופרופן (נורופן)']);
    }
    
    if (complaint.contains('נקע') || complaint.contains('חבלה')) {
      diagnoses.add('חבלה קהה / חשד לנקע');
      treatments.add('• חבלה/נקע: עקרון PRICE, חבישה אלסטית, הפניה לצילום במידת הצורך.');
      redFlags.addAll(['עיוות בולט של הגפה', 'חוסר יכולת לדרוך על הרגל', 'היעדר דופק פריפרי']);
      medications.addAll(['אקמול', 'אופטלגין']);
    }
    
    if (complaint.contains('פטרת') || complaint.contains('פריחה') || complaint.contains('עור')) {
      diagnoses.add('נגע עורי / פטרת / פריחה');
      treatments.add('• פטרת/פריחה: אוורור ושמירה על יובש, מריחת משחה ייעודית.');
      redFlags.addAll(['פריחה המלווה בחום', 'פריחה שאינה מלבינה בלחיצה', 'נפיחות מהירה בפנים']);
      medications.addAll(['משחה לפטרת', 'משחת החתלה לשפשפות']);
    }
    
    if (complaint.contains('טראומה') || complaint.contains('קטסטרופה') || complaint.contains('phtls') || complaint.contains('PHTLS')) {
      diagnoses.add('פצוע טראומה');
      treatments.add('• טראומה: סכמת PHTLS, הרחק מסכנה, פינוי דחוף.');
      redFlags.addAll(['דימום פורץ קטסטרופלי', 'חסימת נתיב אוויר', 'ירידה במצב ההכרה']);
      medications.addAll(['חמצן', 'החייאת נוזלים', 'חסם עורקים']);
    }
    
    if (complaint.contains('רופא') || complaint.contains('גימל') || complaint.contains('תור')) {
      diagnoses.add('בקשה מנהלתית לרופא');
      treatments.add('• תור לרופא: תשאול מלא, בדיקת מדדים שגרתית, קביעת תור בהתאם לדחיפות.');
      redFlags.add('תלונה אקוטית שמוסתרת כבקשה שגרתית');
    }

    if (diagnoses.isEmpty) {
      return {
        'diagnosis': 'תלונה כללית (לא ספציפית)',
        'treatment': '1. בצע מדדים מלאים (לחץ דם, דופק, חום, סטורציה).\n2. המשך תשאול (אנמנזה) לבחינת כיוונים נוספים.\n3. במקרה של החמרה - התייעצות רופא.',
        'redFlags': ['התדרדרות במצב ההכרה', 'מדדים חריגים מאוד'],
        'medications': [],
      };
    }

    return {
      'diagnosis': diagnoses.join(' + '),
      'treatment': treatments.join('\n'),
      'redFlags': redFlags.toSet().toList(),
      'medications': medications.toSet().toList(),
    };
  }
}

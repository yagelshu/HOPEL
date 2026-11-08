import 'dart:async';

/// Deterministic clinical decision helper and allergy cross-checker for field complaints.
class MedicalCopilotService {
  /// Analyzes the medical complaint against structured clinical rules and cross-checks
  /// known [allergies] on the soldier's record immediately (without artificial delays).
  Future<Map<String, dynamic>> analyzeSymptoms(
    String complaint, {
    String? allergies,
  }) async {
    final trimmedComplaint = complaint.trim();
    final trimmedAllergies = (allergies ?? '').trim();

    if (trimmedComplaint.isEmpty) {
      return {
        'diagnosis': 'לא סופק תיאור מספיק',
        'treatment': 'נא להזין תלונות או תגיות רלוונטיות לקבלת הנחיות טיפול.',
        'redFlags': <String>[],
        'medications': <String>[],
        'allergyWarnings': trimmedAllergies.isNotEmpty
            ? <String>['רגישות רשומה בתיק החייל: $trimmedAllergies']
            : <String>[],
      };
    }

    final lower = trimmedComplaint.toLowerCase();
    final List<String> diagnoses = [];
    final List<String> treatments = [];
    final List<String> redFlags = [];
    final List<String> medications = [];

    if (lower.contains('בטן') || lower.contains('שלשול')) {
      diagnoses.add('חשד לגסטרואנטריטיס / זיהום במערכת העיכול');
      treatments.add('• בטן/שלשולים: מנוחה, שתייה מרובה (מומלץ ORS/מי מלח), מעקב חום.');
      redFlags.addAll(['חום מעל 38.5 לאורך זמן', 'דם בצואה', 'סימני התייבשות']);
      medications.addAll(['כדורי אימודיום', 'אקמול (500 מ"ג)']);
    }

    if (lower.contains('ראש') || lower.contains('מיגרנה')) {
      diagnoses.add('כאב ראש / חשד להתייבשות');
      treatments.add('• כאב ראש: מנוחה בחדר חשוך ושקט, שתיית מים מרובה, מדידת לחץ דם ודופק.');
      redFlags.addAll(['הקאות מרובות', 'כאב ראש פתאומי ועוצמתי מאוד', 'טשטוש ראייה']);
      medications.addAll(['כדורי אופטלגין', 'כדורי אקמול']);
    }

    if (lower.contains('פצע') ||
        lower.contains('דימום') ||
        lower.contains('שפשוף') ||
        lower.contains('שפשפת') ||
        lower.contains('שפשפות')) {
      diagnoses.add('פצע שטחי / טראומה קלה');
      treatments.add('• פצע/שפשוף: שטיפה עם סליין, חיטוי, וחבישה סטרילית.');
      redFlags.addAll(['דימום שאינו פוסק לאחר לחץ ישיר', 'סימני זיהום מקומי']);
      medications.addAll(['פדים לחיטוי', 'משחה אנטיביוטית (פיוסידם)']);
    }

    if (lower.contains('חום') || lower.contains('צינון')) {
      diagnoses.add('מחלת חום / זיהום ויראלי');
      treatments.add('• מחלת חום: מדידת מדדים, מנוחה ושתייה מרובה.');
      redFlags.addAll(['קשיי נשימה', 'חום מעל 39 שלא יורד', 'ערפול הכרה']);
      medications.addAll(['אקמול', 'אופטלגין', 'לכסניות למציצה']);
    }

    if (lower.contains('גרון')) {
      diagnoses.add('דלקת גרון');
      treatments.add('• גרון: בדיקת לוע, משטח גרון במידת הצורך, שתייה מרובה.');
      redFlags.addAll(['קושי בבליעת רוק', 'קושי בנשימה', 'נפיחות חד צדדית ניכרת']);
      medications.addAll(['לכסניות מציצה', 'אנטיביוטיקה (פניצילין / מוקסיפן - באישור רופא)']);
    }

    if (lower.contains('גב') ||
        lower.contains('ברכיים') ||
        lower.contains('ברך') ||
        lower.contains('שריר')) {
      diagnoses.add('כאב אורתופדי');
      treatments.add('• כאב אורתופדי: בדיקה פיזיקלית, מנוחה, קירור/חימום המקום.');
      redFlags.addAll(['חוסר תחושה/חולשה בגפיים', 'איבוד שליטה על סוגרים', 'כאב בלתי נסבל במנוחה']);
      medications.addAll(['משחת וולטרן', 'איבופרופן (נורופן / אדוויל)']);
    }

    if (lower.contains('נקע') || lower.contains('חבלה')) {
      diagnoses.add('חבלה קהה / חשד לנקע');
      treatments.add('• חבלה/נקע: עקרון PRICE, חבישה אלסטית, הפניה לצילום במידת הצורך.');
      redFlags.addAll(['עיוות בולט של הגפה', 'חוסר יכולת לדרוך על הרגל', 'היעדר דופק פריפרי']);
      medications.addAll(['אקמול', 'אופטלגין']);
    }

    if (lower.contains('פטרת') || lower.contains('פריחה') || lower.contains('עור')) {
      diagnoses.add('נגע עורי / פטרת / פריחה');
      treatments.add('• פטרת/פריחה: אוורור ושמירה על יובש, מריחת משחה ייעודית.');
      redFlags.addAll(['פריחה המלווה בחום', 'פריחה שאינה מלבינה בלחיצה', 'נפיחות מהירה בפנים']);
      medications.addAll(['משחה לפטרת', 'משחת החתלה לשפשפות']);
    }

    if (lower.contains('טראומה') ||
        lower.contains('קטסטרופה') ||
        lower.contains('phtls')) {
      diagnoses.add('פצוע טראומה');
      treatments.add('• טראומה: סכמת PHTLS, הרחק מסכנה, פינוי דחוף ועדכון חוג"ד/רופא.');
      redFlags.addAll(['דימום פורץ קטסטרופלי', 'חסימת נתיב אוויר', 'ירידה במצב ההכרה']);
      medications.addAll(['חמצן', 'החייאת נוזלים / TXA בפרוטוקול', 'חסם עורקים']);
    }

    if (lower.contains('רופא') || lower.contains('גימל') || lower.contains('תור')) {
      diagnoses.add('בקשה מנהלתית לרופא');
      treatments.add('• תור לרופא: תשאול מלא, בדיקת מדדים שגרתית, קביעת תור בהתאם לדחיפות.');
      redFlags.add('תלונה אקוטית שמוסתרת כבקשה שגרתית');
    }

    if (diagnoses.isEmpty) {
      diagnoses.add('דורש הערכת חופ"ל ורופא בסיסית');
      treatments.add('ביצוע תשאול מפורט, מדידת סימנים חיוניים מלאים (דופק, ל"ד, חום, סטורציה).');
      redFlags.addAll(['כאב חריף ופתאומי', 'איבוד הכרה', 'סימנים חיוניים לא תקינים']);
    }

    final allergyCheck = checkAllergyConflicts(
      allergies: trimmedAllergies,
      recommendedMedications: medications.toSet().toList(),
    );

    return {
      'diagnosis': diagnoses.join(' + '),
      'treatment': treatments.join('\n'),
      'redFlags': redFlags.toSet().toList(),
      'medications': allergyCheck.safeMedications,
      'allergyWarnings': allergyCheck.warnings,
    };
  }

  /// Cross-checks recommended treatments against known soldier allergies/sensitivities.
  static AllergyCheckResult checkAllergyConflicts({
    required String? allergies,
    required List<String> recommendedMedications,
  }) {
    final cleanAllergies = (allergies ?? '').trim();
    if (cleanAllergies.isEmpty) {
      return AllergyCheckResult(
        safeMedications: List<String>.from(recommendedMedications),
        warnings: const [],
      );
    }

    final lowerAlg = cleanAllergies.toLowerCase();
    final warnings = <String>[];
    final safeMeds = <String>[];

    final hasG6pd = lowerAlg.contains('g6pd') || lowerAlg.contains('פול');
    final hasOptalgin = lowerAlg.contains('אופטלגין') ||
        lowerAlg.contains('optalgin') ||
        lowerAlg.contains('dipyrone') ||
        lowerAlg.contains('metamizole');
    final hasNsaid = lowerAlg.contains('nsaid') ||
        lowerAlg.contains('נורופן') ||
        lowerAlg.contains('אדוויל') ||
        lowerAlg.contains('איבופרופן') ||
        lowerAlg.contains('ibuprofen') ||
        lowerAlg.contains('וולטרן') ||
        lowerAlg.contains('voltaren') ||
        lowerAlg.contains('אספירין') ||
        lowerAlg.contains('aspirin');
    final hasPenicillin = lowerAlg.contains('פניצילין') ||
        lowerAlg.contains('penicillin') ||
        lowerAlg.contains('מוקסיפן') ||
        lowerAlg.contains('אוגמנטין');
    final hasParacetamol = lowerAlg.contains('אקמול') ||
        lowerAlg.contains('פראצטמול') ||
        lowerAlg.contains('פרצטמול') ||
        lowerAlg.contains('paracetamol') ||
        lowerAlg.contains('דקסמול');

    bool blockedOptalgin = false;
    bool blockedNsaid = false;
    bool blockedPenicillin = false;
    bool blockedParacetamol = false;

    for (final med in recommendedMedications) {
      final mLower = med.toLowerCase();

      if ((hasG6pd || hasOptalgin) &&
          (mLower.contains('אופטלגין') || mLower.contains('optalgin'))) {
        blockedOptalgin = true;
        continue;
      }

      if (hasNsaid &&
          (mLower.contains('איבופרופן') ||
              mLower.contains('נורופן') ||
              mLower.contains('אדוויל') ||
              mLower.contains('וולטרן'))) {
        blockedNsaid = true;
        continue;
      }

      if (hasPenicillin &&
          (mLower.contains('פניצילין') ||
              mLower.contains('מוקסיפן') ||
              mLower.contains('אוגמנטין') ||
              mLower.contains('אנטיביוטיקה'))) {
        blockedPenicillin = true;
        continue;
      }

      if (hasParacetamol &&
          (mLower.contains('אקמול') || mLower.contains('paracetamol'))) {
        blockedParacetamol = true;
        continue;
      }

      safeMeds.add(med);
    }

    if (blockedOptalgin) {
      warnings.add(
        hasG6pd
            ? 'חסימת בטיחות (G6PD): אופטלגין הוסר מההמלצות — אסור במתן לרגישים לפול!'
            : 'חסימת בטיחות: אופטלגין הוסר מההמלצות עקב רגישות רשומה בתיק.',
      );
    }
    if (blockedNsaid) {
      warnings.add(
        'חסימת בטיחות (NSAID): איבופרופן/וולטרן הוסרו עקב רגישות רשומה לתרופות נוגדות דלקת.',
      );
    }
    if (blockedPenicillin) {
      warnings.add(
        'חסימת בטיחות (פניצילין): אנטיביוטיקות מקבוצת הפניצילין הוסרו — יש להיוועץ ברופא לחלופה.',
      );
    }
    if (blockedParacetamol) {
      warnings.add(
        'חסימת בטיחות (פראצטמול): אקמול הוסר מההמלצות עקב רגישות רשומה בתיק.',
      );
    }

    if (warnings.isEmpty) {
      warnings.add('רגישות מתועדת אצל החייל: $cleanAllergies — יש לוודא התאמה לפני כל מתן טיפול.');
    }

    return AllergyCheckResult(safeMedications: safeMeds, warnings: warnings);
  }
}

class AllergyCheckResult {
  final List<String> safeMedications;
  final List<String> warnings;

  const AllergyCheckResult({
    required this.safeMedications,
    required this.warnings,
  });
}

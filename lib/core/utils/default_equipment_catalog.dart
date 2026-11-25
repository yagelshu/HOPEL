import 'package:uuid/uuid.dart';

class DefaultEquipmentCatalog {
  static const List<Map<String, dynamic>> items = [
    // וסט חובש - מתכלה
    {'name': 'תחבושת אלסטית 4 אינץ', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 2},
    {'name': 'קומבאט גז (Combat Gauze) לעצירת דימומים', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 1},
    {'name': 'גזה דחוסה לספיגה ועצירת דימומים', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 2},
    {'name': 'תמיסת הרטמן לעירוי', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 2},
    {'name': 'מים קטנים לשטיפת פצעים (סליין 10 מל)', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 4},
    {'name': 'כדורי אקמול רגילים (500 מג)', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 20},
    {'name': 'כפפות רפואיות חד פעמיות', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 20},
    {'name': 'מחטים למזרקים', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 2},
    {'name': 'מזרקי פלסטיק רגילים 3 סמק', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 6},
    {'name': 'משולשי בד לחבישה וקיבוע', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 4},
    {'name': 'פלסטר מיקרופור (Micropore)', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 5},
    {'name': 'פדים סטריליים מבד גזה', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 11},
    {'name': 'אגד גזה', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 4},
    {'name': 'ונפלון ירוק 18G', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 4},
    {'name': 'ונפלון כתום 14G', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 2},
    {'name': 'ונפלון כחול 22G', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 2},
    {'name': 'תחבושת אישית First Care', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 9},
    {'name': 'תחבושת בטן', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 1},
    {'name': 'שמיכת מילוט', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 1},

    // וסט חובש - קבוע
    {'name': 'גומי חוסם ורידים', 'category': 'וסט חובש', 'item_type': 'קבוע', 'minimum_required': 2},
    {'name': 'חוסמי עורקים לעצירת דימום', 'category': 'וסט חובש', 'item_type': 'קבוע', 'minimum_required': 4},
    {'name': 'מדחום למדידת חום', 'category': 'וסט חובש', 'item_type': 'קבוע', 'minimum_required': 2},
    {'name': 'פנס רפואי קטן', 'category': 'וסט חובש', 'item_type': 'קבוע', 'minimum_required': 1},
    {'name': 'מכשיר לחמצן בדם (מד סטורציה)', 'category': 'וסט חובש', 'item_type': 'קבוע', 'minimum_required': 1},
    {'name': 'מספריים רפואיים חזקים (מלע"כ)', 'category': 'וסט חובש', 'item_type': 'קבוע', 'minimum_required': 1},
    {'name': 'מחטים חלולות לנקז אוויר (AW)', 'category': 'וסט חובש', 'item_type': 'קבוע', 'minimum_required': 1},
    {'name': 'אמצעים לפתיחת נתיב אוויר עליון (נתבי אוויר)', 'category': 'וסט חובש', 'item_type': 'קבוע', 'minimum_required': 2},

    // ארגז חופל - מתכלה
    {'name': 'תחבושת אלסטית 4 אינץ', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 2},
    {'name': 'גזה דחוסה לספיגה ועצירת דימומים', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 4},
    {'name': 'מזרק אפיפן', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 1},
    {'name': 'כדורי אופטלגין', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 50},
    {'name': 'כדורים נגד צרבת', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 30},
    {'name': 'מחטים למזרקים', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 10},
    {'name': 'צמרוני אוזניים / מקלוני צמר גפן', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 100},
    {'name': 'משחה לשפשפות/גירויים', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 5},
    {'name': 'משחה אנטיביוטית (פיוסידם)', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 10},
    {'name': 'פדים או משחה של אלכוהול לחיטוי', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 9},
    {'name': 'בקבוקוני פולידין וסביעור לחיטוי', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 220},
    {'name': 'בקבוקוני חומר חיטוי נוזלי (כלורקסידין)', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 48},
    {'name': 'פלסטר מיקרופור (Micropore)', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 1},
    {'name': 'פלסטרים קטנים לפצעים', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 100},
    {'name': 'פדים סטריליים מבד גזה', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 30},
    {'name': 'אגד גזה', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 10},
    {'name': 'צמר גפן לחיטוי וחבישה', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 2},
    {'name': 'ונפלון ירוק 18G', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 10},
    {'name': 'ונפלון כתום 14G', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 4},
    {'name': 'ונפלון כחול 22G', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 6},
    {'name': 'תמיסת הרטמן לעירוי', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 4},
    {'name': 'כדורי אימודיום', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 200},
    {'name': 'משחת זובירקס', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 2},
    {'name': 'משחה לפטריות', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 1},
    {'name': 'ספריי תכשיר נגד יתושים', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 1},
    {'name': 'תחבושת אישית First Care', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 32},
    {'name': 'כדורי אקמול רגילים (500 מג)', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 10},

    // ארגז חופל - קבוע
    {'name': 'ארגז עזרה ראשונה (הקופסה עצמה)', 'category': 'ארגז חופל', 'item_type': 'קבוע', 'minimum_required': 1},
    {'name': 'פנקס הפניות רופא (טופס 102)', 'category': 'ארגז חופל', 'item_type': 'קבוע', 'minimum_required': 1},
    {'name': 'פנקס רישום במרפאה (טופס 135)', 'category': 'ארגז חופל', 'item_type': 'קבוע', 'minimum_required': 1},
    {'name': 'מדחום למדידת חום', 'category': 'ארגז חופל', 'item_type': 'קבוע', 'minimum_required': 4},
    {'name': 'מד לחץ דם ידני עם סטטוסקופ', 'category': 'ארגז חופל', 'item_type': 'קבוע', 'minimum_required': 1},
    {'name': 'מספרי חובשים', 'category': 'ארגז חופל', 'item_type': 'קבוע', 'minimum_required': 1},
    {'name': 'סטטוסקופ רפואי', 'category': 'ארגז חופל', 'item_type': 'קבוע', 'minimum_required': 2},
  ];

  static List<Map<String, dynamic>> buildRowsForUnit(
    String unitId, {
    List<Map<String, dynamic>>? catalogSource,
  }) {
    const uuid = Uuid();
    final source = (catalogSource != null && catalogSource.isNotEmpty) ? catalogSource : items;
    return source.map((item) {
      final minReq = (item['minimum_required'] as num?)?.toInt() ?? 1;
      return <String, dynamic>{
        'id': uuid.v4(),
        'name': item['name'],
        'quantity': minReq,
        'minimum_required': minReq,
        'status': 'IN_STOCK',
        'category': item['category'] ?? 'וסט חובש',
        'item_type': item['item_type'] ?? 'מתכלה',
        'unit_id': unitId,
      };
    }).toList();
  }

  /// Builds the standard IDF `וסט חובש` rows assigned personally to [medicId].
  static List<Map<String, dynamic>> buildMedicVestRows(String unitId, String medicId) {
    const uuid = Uuid();
    final vestTemplate = items.where((item) => item['category'] == 'וסט חובש');
    return vestTemplate.map((item) {
      final minReq = (item['minimum_required'] as num?)?.toInt() ?? 1;
      return <String, dynamic>{
        'id': uuid.v4(),
        'name': item['name'],
        'quantity': minReq,
        'minimum_required': minReq,
        'status': 'IN_STOCK',
        'category': 'וסט חובש::$medicId',
        'item_type': item['item_type'] ?? 'מתכלה',
        'unit_id': unitId,
      };
    }).toList();
  }
}


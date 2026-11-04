import 'package:uuid/uuid.dart';

class DefaultEquipmentCatalog {
  static const List<Map<String, dynamic>> items = [
    // וסט חובש - מתכלה
    {'name': 'תחבושת אלסטית חומה רגילה 4 אינץ', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 2},
    {'name': 'תחבושת מיוחדת שעוצרת דימומים', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 1},
    {'name': 'שקיות נוזלים לעירוי (הרטמן 500 מל)', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 2},
    {'name': 'מים קטנים לשטיפת פצעים (סליין 10 מל)', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 4},
    {'name': 'כדורי אקמול רגילים (500 מג)', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 20},
    {'name': 'כפפות רפואיות חד פעמיות', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 20},
    {'name': 'מחטים למזרקים', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 2},
    {'name': 'מזרקי פלסטיק רגילים 3 סמק', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 6},
    {'name': 'משולשי בד לחבישה וקיבוע', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 4},
    {'name': 'גלילי פלסטר רפואי דביק', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 5},
    {'name': 'פדים סטריליים מבד גזה', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 11},
    {'name': 'מחטי וונפלון פלסטיק לעירוי', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 7},
    {'name': 'תחבושות אישיות ושדה (ירוקות)', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 9},
    {'name': 'תחבושת גדולה מאוד לבטן', 'category': 'וסט חובש', 'item_type': 'מתכלה', 'minimum_required': 1},

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
    {'name': 'תחבושת אלסטית חומה רגילה 4 אינץ', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 2},
    {'name': 'מזרק אפיפן', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 1},
    {'name': 'כדורי אופטלגין', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 50},
    {'name': 'כדורים נגד צרבת', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 30},
    {'name': 'מחטים למזרקים', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 10},
    {'name': 'מקלוני עץ ארוכים עם צמר גפן', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 100},
    {'name': 'משחה לשפשפות/גירויים', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 5},
    {'name': 'משחה אנטיביוטית (פיוסידם)', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 10},
    {'name': 'פדים או משחה של אלכוהול לחיטוי', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 9},
    {'name': 'בקבוקוני פולידין וסביעור לחיטוי', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 220},
    {'name': 'בקבוקוני חומר חיטוי נוזלי (כלורקסידין)', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 48},
    {'name': 'גליל פלסטר דביק', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 1},
    {'name': 'פלסטרים קטנים לפצעים', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 100},
    {'name': 'פדים סטריליים מבד גזה', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 30},
    {'name': 'שקיות צמר גפן גדולות', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 2},
    {'name': 'כדורי אימודיום', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 200},
    {'name': 'משחת זובירקס', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 2},
    {'name': 'משחה לפטריות', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 1},
    {'name': 'ספריי תכשיר נגד יתושים', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 1},
    {'name': 'תחבושות אישיות לחבישה', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 32},
    {'name': 'כדורי אקמול רגילים (500 מג)', 'category': 'ארגז חופל', 'item_type': 'מתכלה', 'minimum_required': 10},

    // ארגז חופל - קבוע
    {'name': 'ארגז עזרה ראשונה (הקופסה עצמה)', 'category': 'ארגז חופל', 'item_type': 'קבוע', 'minimum_required': 1},
    {'name': 'פנקס הפניות רופא (טופס 102)', 'category': 'ארגז חופל', 'item_type': 'קבוע', 'minimum_required': 1},
    {'name': 'פנקס רישום במרפאה (טופס 135)', 'category': 'ארגז חופל', 'item_type': 'קבוע', 'minimum_required': 1},
    {'name': 'מדחום למדידת חום', 'category': 'ארגז חופל', 'item_type': 'קבוע', 'minimum_required': 4},
    {'name': 'מד לחץ דם ידני', 'category': 'ארגז חופל', 'item_type': 'קבוע', 'minimum_required': 1},
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
}

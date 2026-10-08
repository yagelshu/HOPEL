import 'database_repository.dart';
import 'package:uuid/uuid.dart';

class MockDatabaseRepository implements DatabaseRepository {
  Map<String, List<Map<String, dynamic>>> data = {
    'medical_cases': [],
    'equipment': [],
    'equipment_assignments': [],
    'learning_content': [],
    'soldiers': [],
    'users': [],
    'units': [],
    'notes': [],
    'deployments': [],
    'daily_schedule': [],
  };

  void Function()? onDataChanged;

  Future<void> seed() async {
    if (data['users']!.isNotEmpty) return;
    
    const uuid = Uuid();
    // Only essential setup like unit creation and equipment
    final unit1 = uuid.v4();
    data['units']!.add({'id': unit1, 'name': 'פלוגה ג'});

    data['equipment']!.clear();
    void addEquip(String name, String group, String type, int qty) {
      data['equipment']!.add({
        'id': uuid.v4(),
        'name': name,
        'category': group,
        'item_type': type,
        'quantity': qty,
        'minimum_required': qty,
        'status': 'READY',
        'unit_id': unit1
      });
    }

    // וסט חובש - מתכלה
    addEquip('תחבושת אלסטית חומה רגילה 4 אינץ', 'וסט חובש', 'מתכלה', 2);
    addEquip('תחבושת מיוחדת שעוצרת דימומים', 'וסט חובש', 'מתכלה', 1);
    addEquip('שקיות נוזלים לעירוי (הרטמן 500 מל)', 'וסט חובש', 'מתכלה', 2);
    addEquip('מים קטנים לשטיפת פצעים (סליין 10 מל)', 'וסט חובש', 'מתכלה', 4);
    addEquip('כדורי אקמול רגילים (500 מג)', 'וסט חובש', 'מתכלה', 20);
    addEquip('כפפות רפואיות חד פעמיות', 'וסט חובש', 'מתכלה', 20);
    addEquip('מחטים למזרקים', 'וסט חובש', 'מתכלה', 2);
    addEquip('מזרקי פלסטיק רגילים 3 סמק', 'וסט חובש', 'מתכלה', 6);
    addEquip('משולשי בד לחבישה וקיבוע', 'וסט חובש', 'מתכלה', 4);
    addEquip('גלילי פלסטר רפואי דביק', 'וסט חובש', 'מתכלה', 5);
    addEquip('פדים סטריליים מבד גזה', 'וסט חובש', 'מתכלה', 11);
    addEquip('מחטי וונפלון פלסטיק לעירוי', 'וסט חובש', 'מתכלה', 7);
    addEquip('תחבושות אישיות ושדה (ירוקות)', 'וסט חובש', 'מתכלה', 9);
    addEquip('תחבושת גדולה מאוד לבטן', 'וסט חובש', 'מתכלה', 1);

    // וסט חובש - קבוע
    addEquip('גומי חוסם ורידים', 'וסט חובש', 'קבוע', 2);
    addEquip('חוסמי עורקים לעצירת דימום', 'וסט חובש', 'קבוע', 4);
    addEquip('מדחום למדידת חום', 'וסט חובש', 'קבוע', 2);
    addEquip('פנס רפואי קטן', 'וסט חובש', 'קבוע', 1);
    addEquip('מכשיר לחמצן בדם (מד סטורציה)', 'וסט חובש', 'קבוע', 1);
    addEquip('מספריים רפואיים חזקים (מלע"כ)', 'וסט חובש', 'קבוע', 1);
    addEquip('מחטים חלולות לנקז אוויר (AW)', 'וסט חובש', 'קבוע', 1);
    addEquip('אמצעים לפתיחת נתיב אוויר עליון (נתבי אוויר)', 'וסט חובש', 'קבוע', 2);

    // ארגז חופל - מתכלה
    addEquip('תחבושת אלסטית חומה רגילה 4 אינץ', 'ארגז חופל', 'מתכלה', 2);
    addEquip('מזרק אפיפן', 'ארגז חופל', 'מתכלה', 1);
    addEquip('כדורי אופטלגין', 'ארגז חופל', 'מתכלה', 50);
    addEquip('כדורים נגד צרבת', 'ארגז חופל', 'מתכלה', 30);
    addEquip('מחטים למזרקים', 'ארגז חופל', 'מתכלה', 10);
    addEquip('מקלוני עץ ארוכים עם צמר גפן', 'ארגז חופל', 'מתכלה', 100);
    addEquip('משחה לשפשפות/גירויים', 'ארגז חופל', 'מתכלה', 5);
    addEquip('משחה אנטיביוטית (פיוסידם)', 'ארגז חופל', 'מתכלה', 10);
    addEquip('פדים או משחה של אלכוהול לחיטוי', 'ארגז חופל', 'מתכלה', 9);
    addEquip('בקבוקוני פולידין וסביעור לחיטוי', 'ארגז חופל', 'מתכלה', 220);
    addEquip('בקבוקוני חומר חיטוי נוזלי (כלורקסידין)', 'ארגז חופל', 'מתכלה', 48);
    addEquip('גליל פלסטר דביק', 'ארגז חופל', 'מתכלה', 1);
    addEquip('פלסטרים קטנים לפצעים', 'ארגז חופל', 'מתכלה', 100);
    addEquip('פדים סטריליים מבד גזה', 'ארגז חופל', 'מתכלה', 30);
    addEquip('שקיות צמר גפן גדולות', 'ארגז חופל', 'מתכלה', 2);
    addEquip('כדורי אימודיום', 'ארגז חופל', 'מתכלה', 200);
    addEquip('משחת זובירקס', 'ארגז חופל', 'מתכלה', 2);
    addEquip('משחה לפטריות', 'ארגז חופל', 'מתכלה', 1);
    addEquip('ספריי תכשיר נגד יתושים', 'ארגז חופל', 'מתכלה', 1);
    addEquip('תחבושות אישיות לחבישה', 'ארגז חופל', 'מתכלה', 32);
    addEquip('כדורי אקמול רגילים (500 מג)', 'ארגז חופל', 'מתכלה', 10);

    // ארגז חופל - קבוע
    addEquip('ארגז עזרה ראשונה (הקופסה עצמה)', 'ארגז חופל', 'קבוע', 1);
    addEquip('פנקס הפניות רופא (טופס 102)', 'ארגז חופל', 'קבוע', 1);
    addEquip('פנקס רישום במרפאה (טופס 135)', 'ארגז חופל', 'קבוע', 1);
    addEquip('מדחום למדידת חום', 'ארגז חופל', 'קבוע', 4);
    addEquip('מד לחץ דם ידני', 'ארגז חופל', 'קבוע', 1);
    addEquip('מספרי חובשים', 'ארגז חופל', 'קבוע', 1);
    addEquip('סטטוסקופ רפואי', 'ארגז חופל', 'קבוע', 2);


    final categories = {
      'ציר אנטומיה': [
        {'title': 'יסודות מבנה הגוף', 'file': 'ציר אנטומיה- יסודות מבנה הגוף.pdf'},
        {'title': 'מערכת הנשימה', 'file': 'ציר אנטומיה - מערכת הנשימה.pdf'},
        {'title': 'מערכת ההובלה', 'file': 'ציר אנטומיה - מערכת ההובלה.pdf'},
        {'title': 'מערכת העצבים', 'file': 'ציר אנטומיה - מערכת העצבים.pdf'},
      ],
      'ציר טראומה': [
        {'title': 'עצירת דימומים', 'file': 'ציר טראומה - עצירת דימומים.pdf'},
        {'title': 'קינימטיקה בטראומה', 'file': 'קינימטיקה בטראומה.pdf'},
        {'title': 'פגיעות שונות', 'file': 'ציר טראומה - פגיעות שונות.pdf'},
        {'title': 'תגובת קרב ודחק', 'file': 'תגובת קרב & דחק.pdf'},
        {'title': 'אוכלוסיות מיוחדות', 'file': 'אוכלוסיות מיוחדות.pdf'},
        {'title': 'שמירה על עמש"צ', 'file': 'ציר טראומה - שמירה על עמוד שדרה צווארי.pdf'},
        {'title': 'פרוצדורות', 'file': 'פרוצדרות - נקז חזה, זונדה, גישה ורידית חלופית.pdf'},
        {'title': 'פגיעות AR', 'file': 'ציר טראומה - שלבים AR.pdf'},
        {'title': 'פגיעות הלם', 'file': 'פגיעות הלם.pdf'},
        {'title': 'סקר שניוני והטיפול המתמשך', 'file': 'ציר טראומה- סקר שניוני וטיפול מתמשך.pdf'},
        {'title': 'טיפול בכאב', 'file': 'טיפול בכאב.pdf'},
        {'title': 'גישה ורידית', 'file': 'ציר טראומה - גישה ורידית.pdf'},
        {'title': 'אירוע רב נפגעים', 'file': 'ציר טראומה - אירוע רב נפגעים.pdf'},
        {'title': 'חבישות וקיבועים', 'file': 'חבישות וקיבועים.pdf'},
        {'title': 'מבוא לטראומה', 'file': 'ציר טראומה - מבוא.pdf'},
        {'title': 'שלבים XC', 'file': 'ציר טראומה - שלבים XC.pdf'},
        {'title': 'הערכה וניהול נתיב אוויר', 'file': 'הערכה וניהול נתיב אוויר.pdf'},
        {'title': 'פגיעות אקלים חם', 'file': 'פגיעות אקלים חם.pdf'},
        {'title': 'פגיעות אקלים קר', 'file': 'פגיעות אקלים קר.pdf'},
        {'title': 'שלבים ARE', 'file': 'ציר טראומה - שלבים ARE.pdf'},
        {'title': 'החייאת בקרת נזקים בשדה', 'file': 'ציר טראומה - החייאת בקרת נזקים בשדה.pdf'},
        {'title': 'סמכת טיפול בפצוע - XCARE', 'file': 'סכמת XCARE.pdf'},
        {'title': 'עבודה עם מחצי"ם', 'file': 'מצגת - עבודה עם מחצים - אוקטובר 2023 2.pptx'},
      ],
      'ציר החייאה': [
        {'title': 'החייאת מבוגר', 'file': 'החייאת מבוגר.pdf'},
        {'title': 'החייאת ילדים ותינוקות', 'file': 'החייאת ילדים ותינוקות.pdf'},
        {'title': 'סילוק גוף זר', 'file': 'חנק - סילוק גוף זר.pdf'},
        {'title': 'מכשירי החייאה', 'file': 'מכשירי החייאה.pdf'},
      ],
      'ציר שגרה': [
        {'title': 'חשיפה לדם', 'file': 'חשיפה לדם.pdf'},
        {'title': 'גישה ורידית ושאיבות דם', 'file': 'גישה ורידית ושאיבות דם מהוריד.pdf'},
      ],
    };

    data['daily_schedule'] = [
      {
        'id': uuid.v4(),
        'time': '08:00',
        'title': 'מסדר חולים',
        'icon': 'stethoscope',
        'is_done': 1,
        'actor': 'חובש תורן',
      },
      {
        'id': uuid.v4(),
        'time': '12:00',
        'title': 'ספירת מלאי ותוקף ארגז חופל',
        'icon': 'package',
        'is_done': 0,
        'actor': 'חופ"ל',
      },
      {
        'id': uuid.v4(),
        'time': '16:00',
        'title': 'מסדר ערב',
        'icon': 'clock',
        'is_done': 0,
        'actor': 'חובש תורן',
      },
    ];

    categories.forEach((category, items) {
      for (var item in items) {
        data['learning_content']!.add({
          'id': uuid.v4(),
          'title': item['title'],
          'type': 'PDF',
          'category': category,
          'url': 'assets/learning_materials/${item['file']}'
        });
      }
    });
  }

  @override
  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<Object?>? whereArgs, String? orderBy}) async {
    if (where == 'id = ?' && whereArgs != null && whereArgs.isNotEmpty) {
      final id = whereArgs[0];
      return data[table]!.where((row) => row['id'] == id).toList();
    }
    return data[table] ?? [];
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    if (sql.contains("FROM medical_cases WHERE status != 'CLOSED'")) {
      final count = data['medical_cases']!.where((c) => c['status'] != 'CLOSED').length;
      return [{'COUNT(*)': count}];
    }
    if (sql.contains("FROM medical_cases WHERE status = 'REQUIRES_ATTENTION'")) {
      final count = data['medical_cases']!.where((c) => c['status'] == 'REQUIRES_ATTENTION').length;
      return [{'COUNT(*)': count}];
    }
    if (sql.contains("FROM equipment WHERE status = 'MISSING' OR quantity < minimum_required")) {
      final count = data['equipment']!.where((c) => c['status'] == 'MISSING' || (c['quantity'] as int) < (c['minimum_required'] as int)).length;
      return [{'COUNT(*)': count}];
    }
    if (sql.contains("FROM equipment WHERE status = 'EXPIRING_SOON'")) {
      final count = data['equipment']!.where((c) => c['status'] == 'EXPIRING_SOON').length;
      return [{'COUNT(*)': count}];
    }
    if (sql.contains("FROM equipment_assignments WHERE verification_status = 'PENDING'")) {
      final count = data['equipment_assignments']!.where((c) => c['verification_status'] == 'PENDING').map((c) => c['medic_id']).toSet().length;
      return [{'COUNT(DISTINCT medic_id)': count}];
    }
    if (sql.contains('COUNT(*)')) {
      return [{'COUNT(*)': 0}];
    }
    return [];
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values) async {
    final list = data[table];
    if (list != null) {
      if (values.containsKey('id')) {
        final existingIndex = list.indexWhere((element) => element['id'] == values['id']);
        if (existingIndex != -1) {
          list[existingIndex] = {...list[existingIndex], ...values};
        } else {
          list.add(Map<String, dynamic>.from(values));
        }
      } else {
        list.add(Map<String, dynamic>.from(values));
      }
    }
    onDataChanged?.call();
    return 1;
  }

  @override
  Future<int> update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs}) async {
    if (where == 'id = ?' && whereArgs != null && whereArgs.isNotEmpty) {
      final id = whereArgs[0];
      final list = data[table]!;
      for (int i = 0; i < list.length; i++) {
        if (list[i]['id'] == id) {
          list[i] = {...list[i], ...values};
          onDataChanged?.call();
          return 1;
        }
      }
    }
    return 1;
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    if (where == 'id = ?' && whereArgs != null && whereArgs.isNotEmpty) {
      final id = whereArgs[0];
      data[table]?.removeWhere((item) => item['id'] == id);
      onDataChanged?.call();
    }
    onDataChanged?.call();
    return 1;
  }

  @override
  Future<void> clear() async {
    final tables = [
      'units',
      'users',
      'soldiers',
      'medical_cases',
      'equipment_assignments',
      'audit_logs',
      'sync_queue',
      'deployments',
      'notes',
      'daily_schedule',
      'equipment',
      'learning_content',
    ];
    for (final table in tables) {
      data[table] = [];
    }
    onDataChanged?.call();
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseRepository txn) action) async {
    return await action(this);
  }
}

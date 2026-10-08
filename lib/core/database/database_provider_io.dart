import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'database_repository.dart';
import 'sqlite_database_repository.dart';

Future<DatabaseRepository> getPlatformDatabase() async {
  String path = join(await getDatabasesPath(), 'hopal_app.db');
  final db = await openDatabase(
    path,
    version: 14, 
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
  );
  return SqliteDatabaseRepository(db);
}

Future<void> _onCreate(Database db, int version) async {
  await _migrationV1(db);
  if (version >= 2) await _migrationV2(db);
  if (version >= 3) await _migrationV3(db);
  if (version >= 4) await _migrationV4(db);
  if (version >= 5) await _migrationV5(db);
  if (version >= 6) await _migrationV6(db);
  if (version >= 7) await _migrationV7(db);
  if (version >= 8) await _migrationV8(db);
  if (version >= 9) await _migrationV9(db);
  if (version >= 10) await _migrationV10(db);
  if (version >= 11) await _migrationV11(db);
  if (version >= 12) await _migrationV12(db);
  if (version >= 13) await _migrationV13(db);
  if (version >= 14) await _migrationV14(db);
  
  // Seed data after ALL migrations are complete so all columns exist
  await _seedDevelopmentData(db);
}

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) await _migrationV2(db); 
  if (oldVersion < 3) await _migrationV3(db); 
  if (oldVersion < 4) await _migrationV4(db); 
  if (oldVersion < 5) await _migrationV5(db); 
  if (oldVersion < 6) await _migrationV6(db); 
  if (oldVersion < 7) await _migrationV7(db); 
  if (oldVersion < 8) await _migrationV8(db); 
  if (oldVersion < 9) await _migrationV9(db); 
  if (oldVersion < 10) await _migrationV10(db); 
  if (oldVersion < 11) await _migrationV11(db);
  if (oldVersion < 12) await _migrationV12(db);
  if (oldVersion < 13) await _migrationV13(db);
  if (oldVersion < 14) await _migrationV14(db);
}

Future<void> _migrationV1(Database db) async {
  await db.execute('''
    CREATE TABLE units (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      join_code TEXT
    )
  ''');

  await db.execute('''
    CREATE TABLE users (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      role TEXT NOT NULL,
      unit_id TEXT,
      active_deployment_id TEXT,
      competence_points INTEGER DEFAULT 0,
      is_on_standby INTEGER DEFAULT 1,
      FOREIGN KEY (unit_id) REFERENCES units (id)
    )
  ''');

  await db.execute('''
    CREATE TABLE soldiers (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      platoon TEXT,
      phone_number TEXT,
      unit_id TEXT,
      FOREIGN KEY (unit_id) REFERENCES units (id)
    )
  ''');

  await db.execute('''
    CREATE TABLE medical_cases (
      id TEXT PRIMARY KEY,
      soldier_id TEXT NOT NULL,
      status TEXT NOT NULL,
      description TEXT,
      follow_up_date TEXT,
      created_date TEXT NOT NULL,
      closed_date TEXT,
      image_path TEXT,
      deployment_id TEXT,
      FOREIGN KEY (soldier_id) REFERENCES soldiers (id)
    )
  ''');

  await db.execute('''
    CREATE TABLE equipment (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      quantity INTEGER NOT NULL DEFAULT 0,
      minimum_required INTEGER NOT NULL DEFAULT 0,
      expiration_date TEXT,
      status TEXT NOT NULL,
      category TEXT DEFAULT 'כללי',
      item_type TEXT DEFAULT 'מתכלה',
      unit_id TEXT,
      FOREIGN KEY (unit_id) REFERENCES units (id)
    )
  ''');

  await db.execute('''
    CREATE TABLE equipment_assignments (
      id TEXT PRIMARY KEY,
      equipment_id TEXT NOT NULL,
      medic_id TEXT NOT NULL,
      verification_status TEXT NOT NULL,
      FOREIGN KEY (equipment_id) REFERENCES equipment (id),
      FOREIGN KEY (medic_id) REFERENCES users (id)
    )
  ''');

  await db.execute('''
    CREATE TABLE learning_content (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      type TEXT NOT NULL,
      category TEXT NOT NULL,
      url TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE audit_logs (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      action TEXT NOT NULL,
      entity_type TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      timestamp TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (id)
    )
  ''');

  await db.execute('''
    CREATE TABLE sync_queue (
      id TEXT PRIMARY KEY,
      entity_type TEXT NOT NULL,
      action TEXT NOT NULL,
      payload TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  ''');
}

Future<void> _migrationV2(Database db) async {
  try {
    await db.execute('ALTER TABLE medical_cases ADD COLUMN updated_date TEXT;');
  } catch (_) {}
}

Future<void> _migrationV5(Database db) async {
  try {
    await db.execute('ALTER TABLE medical_cases ADD COLUMN image_path TEXT;');
  } catch (_) {}
}

Future<void> _migrationV6(Database db) async {
  try {
    await db.execute('''
      CREATE TABLE deployments (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT,
        unit_id TEXT,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (unit_id) REFERENCES units (id)
      )
    ''');
  } catch (_) {}
  try {
    await db.execute('ALTER TABLE users ADD COLUMN active_deployment_id TEXT;');
  } catch (_) {}
  try {
    await db.execute('ALTER TABLE medical_cases ADD COLUMN deployment_id TEXT;');
  } catch (_) {}
}

Future<void> _migrationV7(Database db) async {
  try {
    await db.execute('ALTER TABLE units ADD COLUMN join_code TEXT;');
  } catch (_) {}
}

Future<void> _migrationV3(Database db) async {
  final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM learning_content'));
  if (count == 0) {
    const uuid = Uuid();
    await db.insert('learning_content', {
      'id': uuid.v4(),
      'title': 'פרוטוקול טיפול בפצוע טראומה (Trauma Protocol)',
      'type': 'PDF',
      'category': 'Protocols',
      'url': 'https://example.com/trauma_protocol.pdf'
    });
    await db.insert('learning_content', {
      'id': uuid.v4(),
      'title': 'הנחיות חסם עורקים (Tourniquet Guidelines)',
      'type': 'VIDEO',
      'category': 'Training',
      'url': 'https://example.com/tourniquet_video.mp4'
    });
    await db.insert('learning_content', {
      'id': uuid.v4(),
      'title': 'טיפול שגרתי בצה"ל (Routine Care)',
      'type': 'DOC',
      'category': 'Protocols',
      'url': 'https://example.com/routine_care.pdf'
    });
  }
}

Future<void> _seedDevelopmentData(Database db) async {
  const uuid = Uuid();
  final now = DateTime.now().toIso8601String();

  final unit1 = uuid.v4();
  await db.insert('units', {'id': unit1, 'name': 'פלוגה ג'});

  final companyMedicId = uuid.v4();
  final combatMedic1Id = uuid.v4();
  final combatMedic2Id = uuid.v4();
  final combatMedic3Id = uuid.v4();

  await db.insert('users', {'id': companyMedicId, 'name': 'ד"ר כהן', 'role': 'COMPANY_MEDIC', 'unit_id': unit1});
  await db.insert('users', {'id': combatMedic1Id, 'name': 'לוי (מחלקה 1)', 'role': 'COMBAT_MEDIC', 'unit_id': unit1});
  await db.insert('users', {'id': combatMedic2Id, 'name': 'אברהם (מחלקה 2)', 'role': 'COMBAT_MEDIC', 'unit_id': unit1});
  await db.insert('users', {'id': combatMedic3Id, 'name': 'יוסי (מחלקה 3)', 'role': 'COMBAT_MEDIC', 'unit_id': unit1});

  // Keep the equipment seeding, but remove mock soldiers and cases

  final equipmentList = [
    // וסט חובש - מתכלה
    ['תחבושת אלסטית חומה רגילה 4 אינץ', 'וסט חובש', 'מתכלה', 2],
    ['תחבושת מיוחדת שעוצרת דימומים', 'וסט חובש', 'מתכלה', 1],
    ['שקיות נוזלים לעירוי (הרטמן 500 מל)', 'וסט חובש', 'מתכלה', 2],
    ['מים קטנים לשטיפת פצעים (סליין 10 מל)', 'וסט חובש', 'מתכלה', 4],
    ['כדורי אקמול רגילים (500 מג)', 'וסט חובש', 'מתכלה', 20],
    ['כפפות רפואיות חד פעמיות', 'וסט חובש', 'מתכלה', 20],
    ['מחטים למזרקים', 'וסט חובש', 'מתכלה', 2],
    ['מזרקי פלסטיק רגילים 3 סמק', 'וסט חובש', 'מתכלה', 6],
    ['משולשי בד לחבישה וקיבוע', 'וסט חובש', 'מתכלה', 4],
    ['גלילי פלסטר רפואי דביק', 'וסט חובש', 'מתכלה', 5],
    ['פדים סטריליים מבד גזה', 'וסט חובש', 'מתכלה', 11],
    ['מחטי וונפלון פלסטיק לעירוי', 'וסט חובש', 'מתכלה', 7],
    ['תחבושות אישיות ושדה (ירוקות)', 'וסט חובש', 'מתכלה', 9],
    ['תחבושת גדולה מאוד לבטן', 'וסט חובש', 'מתכלה', 1],

    // וסט חובש - קבוע
    ['גומי חוסם ורידים', 'וסט חובש', 'קבוע', 2],
    ['חוסמי עורקים לעצירת דימום', 'וסט חובש', 'קבוע', 4],
    ['מדחום למדידת חום', 'וסט חובש', 'קבוע', 2],
    ['פנס רפואי קטן', 'וסט חובש', 'קבוע', 1],
    ['מכשיר לחמצן בדם (מד סטורציה)', 'וסט חובש', 'קבוע', 1],
    ['מספריים רפואיים חזקים (מלע"כ)', 'וסט חובש', 'קבוע', 1],
    ['מחטים חלולות לנקז אוויר (AW)', 'וסט חובש', 'קבוע', 1],
    ['אמצעים לפתיחת נתיב אוויר עליון (נתבי אוויר)', 'וסט חובש', 'קבוע', 2],

    // ארגז חופל - מתכלה
    ['תחבושת אלסטית חומה רגילה 4 אינץ', 'ארגז חופל', 'מתכלה', 2],
    ['מזרק אפיפן', 'ארגז חופל', 'מתכלה', 1],
    ['כדורי אופטלגין', 'ארגז חופל', 'מתכלה', 50],
    ['כדורים נגד צרבת', 'ארגז חופל', 'מתכלה', 30],
    ['מחטים למזרקים', 'ארגז חופל', 'מתכלה', 10],
    ['מקלוני עץ ארוכים עם צמר גפן', 'ארגז חופל', 'מתכלה', 100],
    ['משחה לשפשפות/גירויים', 'ארגז חופל', 'מתכלה', 5],
    ['משחה אנטיביוטית (פיוסידם)', 'ארגז חופל', 'מתכלה', 10],
    ['פדים או משחה של אלכוהול לחיטוי', 'ארגז חופל', 'מתכלה', 9],
    ['בקבוקוני פולידין וסביעור לחיטוי', 'ארגז חופל', 'מתכלה', 220],
    ['בקבוקוני חומר חיטוי נוזלי (כלורקסידין)', 'ארגז חופל', 'מתכלה', 48],
    ['גליל פלסטר דביק', 'ארגז חופל', 'מתכלה', 1],
    ['פלסטרים קטנים לפצעים', 'ארגז חופל', 'מתכלה', 100],
    ['פדים סטריליים מבד גזה', 'ארגז חופל', 'מתכלה', 30],
    ['שקיות צמר גפן גדולות', 'ארגז חופל', 'מתכלה', 2],
    ['כדורי אימודיום', 'ארגז חופל', 'מתכלה', 200],
    ['משחת זובירקס', 'ארגז חופל', 'מתכלה', 2],
    ['משחה לפטריות', 'ארגז חופל', 'מתכלה', 1],
    ['ספריי תכשיר נגד יתושים', 'ארגז חופל', 'מתכלה', 1],
    ['תחבושות אישיות לחבישה', 'ארגז חופל', 'מתכלה', 32],
    ['כדורי אקמול רגילים (500 מג)', 'ארגז חופל', 'מתכלה', 10],

    // ארגז חופל - קבוע
    ['ארגז עזרה ראשונה (הקופסה עצמה)', 'ארגז חופל', 'קבוע', 1],
    ['פנקס הפניות רופא (טופס 102)', 'ארגז חופל', 'קבוע', 1],
    ['פנקס רישום במרפאה (טופס 135)', 'ארגז חופל', 'קבוע', 1],
    ['מדחום למדידת חום', 'ארגז חופל', 'קבוע', 4],
    ['מד לחץ דם ידני', 'ארגז חופל', 'קבוע', 1],
    ['מספרי חובשים', 'ארגז חופל', 'קבוע', 1],
    ['סטטוסקופ רפואי', 'ארגז חופל', 'קבוע', 2],
  ];

  for (var item in equipmentList) {
    await db.insert('equipment', {
      'id': uuid.v4(), 
      'name': item[0] as String, 
      'category': item[1] as String,
      'item_type': item[2] as String,
      'quantity': item[3] as int, 
      'minimum_required': item[3] as int,
      'expiration_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
      'status': 'READY', 
      'unit_id': unit1, 
    });
  }
  
  await db.insert('learning_content', {
    'id': uuid.v4(), 'title': 'פרוטוקול טראומה מעודכן 2026', 'type': 'PDF', 'category': 'פרוטוקולים רפואיים', 'url': 'https://example.com/trauma.pdf'
  });
  await db.insert('learning_content', {
    'id': uuid.v4(), 'title': 'הדרכת חסם עורקים אמריקאי', 'type': 'VIDEO', 'category': 'הדרכות', 'url': 'https://example.com/tourniquet.mp4'
  });
}

Future<void> _migrationV4(Database db) async {
  // Add category and item_type to equipment if not exists
  try {
    await db.execute('ALTER TABLE equipment ADD COLUMN category TEXT DEFAULT "כללי"');
  } catch (e) {
    // Column might already exist
  }
  
  try {
    await db.execute('ALTER TABLE equipment ADD COLUMN item_type TEXT DEFAULT "מתכלה"');
  } catch (e) {
    // Column might already exist
  }
}
Future<void> _migrationV8(Database db) async {
  await db.execute('''
    CREATE TABLE notes(
      id TEXT PRIMARY KEY,
      unit_id TEXT NOT NULL,
      user_id TEXT NOT NULL,
      content TEXT NOT NULL,
      is_private INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY(unit_id) REFERENCES units(id)
    )
  ''');
}

Future<void> _migrationV9(Database db) async {
  try {
    await db.execute('ALTER TABLE equipment ADD COLUMN image_path TEXT;');
  } catch (e) {
    // Ignore if exists
  }
}

Future<void> _migrationV10(Database db) async {
  await db.execute('''
    UPDATE equipment 
    SET category = 'וסט חובש' 
    WHERE category = 'כללי' OR category IS NULL
  ''');
}

Future<void> _migrationV11(Database db) async {
  try {
    await db.execute('''
      CREATE TABLE daily_schedule (
        id TEXT PRIMARY KEY,
        time TEXT NOT NULL,
        title TEXT NOT NULL,
        is_done INTEGER DEFAULT 0
      )
    ''');
  } catch (_) {}
}

Future<void> _migrationV12(Database db) async {
  try {
    await db.execute('ALTER TABLE soldiers ADD COLUMN phone_number TEXT;');
  } catch (_) {}
}

Future<void> _migrationV13(Database db) async {
  try {
    await db.execute('ALTER TABLE users ADD COLUMN competence_points INTEGER DEFAULT 0;');
  } catch (_) {}
}

Future<void> _migrationV14(Database db) async {
  try {
    await db.execute('ALTER TABLE users ADD COLUMN is_on_standby INTEGER DEFAULT 1;');
  } catch (_) {}
}

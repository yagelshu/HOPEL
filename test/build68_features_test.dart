import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chopel_app/core/services/battalion_staff_service.dart';
import 'package:chopel_app/core/services/csv_export_service.dart';
import 'package:chopel_app/core/utils/default_equipment_catalog.dart';
import 'package:chopel_app/core/utils/equipment_photo_catalog.dart';
import 'package:chopel_app/core/utils/equipment_visual_helper.dart';
import 'package:chopel_app/core/utils/platoon_helper.dart';
import 'package:chopel_app/features/dashboard/providers.dart';
import 'package:chopel_app/features/learning/red_flags_guide_screen.dart';
import 'package:chopel_app/features/medical_cases/widgets/inventory_dispense_sheet.dart';
import 'package:chopel_app/models/equipment.dart';
import 'package:chopel_app/models/medical_case.dart';
import 'package:chopel_app/models/soldier.dart';

void main() {
  group('BattalionStaffService - Rotating Matab & Hogad Staff', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('migrates legacy doctor and hogad preferences into staff contacts', () async {
      SharedPreferences.setMockInitialValues({
        'doctor_name': 'ד"ר אלון כהן',
        'doctor_phone_number': '054-1112233',
        'hogad_name': 'סמ"ר רועי לוי',
        'hogad_phone_number': '052-9998877',
      });

      final all = await BattalionStaffService.loadAll();
      expect(all.length, 2);

      final matab = await BattalionStaffService.getActiveContact(BattalionStaffService.groupMatab);
      expect(matab, isNotNull);
      expect(matab!.name, 'ד"ר אלון כהן');
      expect(matab.role, 'רופא');
      expect(matab.isOnDuty, isTrue);

      final hogad = await BattalionStaffService.getActiveContact(BattalionStaffService.groupHogad);
      expect(hogad, isNotNull);
      expect(hogad!.name, 'סמ"ר רועי לוי');
      expect(hogad.role, 'חוג"ד');
      expect(hogad.isOnDuty, isTrue);
    });

    test('supports multiple doctors & paramedics under Matab and switches on-duty cleanly', () async {
      final doc1 = StaffContact(
        id: 'm1',
        name: 'ד"ר יונתן ברק',
        phone: '0501111111',
        role: 'רופא',
        group: BattalionStaffService.groupMatab,
        isOnDuty: true,
        updatedAt: DateTime(2026, 5, 1, 10),
      );
      final doc2 = StaffContact(
        id: 'm2',
        name: 'ד"ר שירה גל',
        phone: '0502222222',
        role: 'רופא',
        group: BattalionStaffService.groupMatab,
        isOnDuty: false,
        updatedAt: DateTime(2026, 5, 1, 10),
      );
      final para1 = StaffContact(
        id: 'm3',
        name: 'עידו (פראמדיק)',
        phone: '0503333333',
        role: 'פראמדיק',
        group: BattalionStaffService.groupMatab,
        isOnDuty: false,
        updatedAt: DateTime(2026, 5, 1, 10),
      );
      final hogad1 = StaffContact(
        id: 'h1',
        name: 'אורי חוג"ד',
        phone: '0504444444',
        role: 'חוג"ד',
        group: BattalionStaffService.groupHogad,
        isOnDuty: true,
        updatedAt: DateTime(2026, 5, 1, 10),
      );
      final hogad2 = StaffContact(
        id: 'h2',
        name: 'נועם מחליף חוג"ד',
        phone: '0505555555',
        role: 'מחליף חוג"ד',
        group: BattalionStaffService.groupHogad,
        isOnDuty: false,
        updatedAt: DateTime(2026, 5, 1, 10),
      );

      await BattalionStaffService.upsertContact(doc1);
      await BattalionStaffService.upsertContact(doc2);
      await BattalionStaffService.upsertContact(para1);
      await BattalionStaffService.upsertContact(hogad1);
      await BattalionStaffService.upsertContact(hogad2);

      expect((await BattalionStaffService.loadGroup(BattalionStaffService.groupMatab)).length, 3);
      expect((await BattalionStaffService.loadGroup(BattalionStaffService.groupHogad)).length, 2);

      // Switch Matab on-duty to paramedic
      await BattalionStaffService.setOnDuty('m3', BattalionStaffService.groupMatab);
      final activeMatab = await BattalionStaffService.getActiveContact(BattalionStaffService.groupMatab);
      expect(activeMatab!.id, 'm3');
      expect(activeMatab.role, 'פראמדיק');

      // Ensure Hogad on-duty was not affected
      final activeHogad = await BattalionStaffService.getActiveContact(BattalionStaffService.groupHogad);
      expect(activeHogad!.id, 'h1');

      // Switch Hogad on-duty to backup hogad
      await BattalionStaffService.setOnDuty('h2', BattalionStaffService.groupHogad);
      final updatedHogad = await BattalionStaffService.getActiveContact(BattalionStaffService.groupHogad);
      expect(updatedHogad!.id, 'h2');
      expect(updatedHogad.role, 'מחליף חוג"ד');
    });

    test('applies cloud config payload and merges contacts', () async {
      final payload = jsonEncode({
        'staff_contacts': [
          {
            'id': 'cloud_m1',
            'name': 'ד"ר ענן',
            'phone': '0547776655',
            'role': 'רופא',
            'group': 'matab',
            'is_on_duty': true,
            'updated_at': DateTime(2026, 6, 1).toIso8601String(),
          }
        ],
        'follow_up_reminders': [],
      });

      await BattalionStaffService.applyCloudConfigContent(
        '${BattalionStaffService.cloudConfigPrefix}$payload',
      );

      final active = await BattalionStaffService.getActiveContact(BattalionStaffService.groupMatab);
      expect(active, isNotNull);
      expect(active!.name, 'ד"ר ענן');
    });

    test('identifies Matab queue cases and builds WhatsApp report', () {
      final c1 = MedicalCase(
        id: '1',
        soldierId: 's1',
        status: 'REQUIRES_ATTENTION',
        category: BattalionStaffService.matabCategory,
        description: '[בדיקת מט"ב] [בקשת תור לרופא] כאבי אוזניים וחום',
        createdDate: DateTime(2026, 5, 10, 9).toIso8601String(),
      );
      final c2 = MedicalCase(
        id: '2',
        soldierId: 's2',
        status: 'COMPLETED',
        category: BattalionStaffService.matabCategory,
        description: '[בדיקת מט"ב] טופל ושוחרר',
        createdDate: DateTime(2026, 5, 10, 8).toIso8601String(),
      );

      expect(BattalionStaffService.isCaseInMatabQueue(c1), isTrue);
      expect(BattalionStaffService.isCaseInMatabQueue(c2), isFalse);

      final soldiers = [
        Soldier(
          id: 's1',
          name: 'דניאל לוי',
          personalNumber: '8123456',
          platoon: 'מחלקה 1',
          allergies: 'פניצילין',
        ),
      ];

      final report = BattalionStaffService.buildMatabQueueMessage(
        cases: [c1, c2],
        soldiers: soldiers,
        unitName: 'פלוגה ב',
      );

      expect(report, contains('מסדר מט"ב / רשימת חיילים לבדיקה'));
      expect(report, contains('דניאל לוי'));
      expect(report, contains('8123456'));
      expect(report, contains('רגישות:* פניצילין'));
      expect(report, contains('כאבי אוזניים וחום'));
    });
  });

  group('InventoryDispenseHelper & CsvExportService', () {
    test('formats dispensed summary cleanly for medical case description', () {
      final summary = InventoryDispenseHelper.formatDispensedSummary(const [
        DispensedItem(
          equipmentId: 'eq1',
          name: 'אקמול 500 מ"ג',
          sourceLabel: 'ארגז חופ"ל',
          quantity: 2,
        ),
        DispensedItem(
          equipmentId: 'eq2',
          name: 'תחבושת אישית',
          sourceLabel: 'הווסט שלי',
          quantity: 1,
        ),
      ]);

      expect(
        summary,
        '💊 נופק מהמלאי: אקמול 500 מ"ג (x2), תחבושת אישית (x1)',
      );
    });

    test('generates UTF-8 BOM CSV for soldiers and medical cases', () {
      final soldiers = [
        Soldier(
          id: 's1',
          name: 'ישראל ישראלי',
          personalNumber: '9001122',
          platoon: 'מחלקה א',
          phoneNumber: '050-1234567',
          allergies: 'G6PD, אופטלגין',
        ),
      ];
      final cases = [
        MedicalCase(
          id: 'c1',
          soldierId: 's1',
          status: 'REQUIRES_ATTENTION',
          category: 'בדיקת מט"ב',
          description: '[בדיקת מט"ב] כאב גרון, נופק סטרפסילס',
          createdDate: '2026-05-12T14:30:00.000',
        ),
      ];

      final soldiersCsv = CsvExportService.generateSoldiersCsv(soldiers);
      expect(soldiersCsv.startsWith('\uFEFF'), isTrue);
      expect(soldiersCsv, contains('ישראל ישראלי'));
      expect(soldiersCsv, contains('"G6PD, אופטלגין"'));

      final casesCsv = CsvExportService.generateMedicalCasesCsv(cases, soldiers);
      expect(casesCsv.startsWith('\uFEFF'), isTrue);
      expect(casesCsv, contains('בטיפול / מעקב'));
      expect(casesCsv, contains('"בדיקת מט""ב"'));
    });

    test('RedFlagsGuideScreen provides clinical pocket guide topics with red flags and actions', () {
      expect(RedFlagsGuideScreen.topics.length, greaterThanOrEqualTo(7));
      for (final topic in RedFlagsGuideScreen.topics) {
        expect(topic.title, isNotEmpty);
        expect(topic.redFlags, isNotEmpty);
        expect(topic.mandatoryChecks, isNotEmpty);
        expect(topic.immediateAction, isNotEmpty);
      }
    });

    test('PlatoonHelper supports מסופחים as a canonical company group', () {
      expect(PlatoonHelper.normalize('מסופחים'), 'מסופחים');
      expect(PlatoonHelper.normalize('מסופח'), 'מסופחים');
      expect(PlatoonHelper.normalize('מחלקה מסופחים'), 'מסופחים');
      expect(PlatoonHelper.quickSelectPlatoons, contains('מסופחים'));

      final extracted = PlatoonHelper.extractPlatoons<Soldier>(
        const [],
        (s) => s.platoon,
        alwaysIncludeAttached: true,
      );
      expect(extracted, contains('מסופחים'));
    });

    test('EquipmentVisualHelper resolves built-in medical illustrations for all standard IDF catalog items', () {
      expect(
        EquipmentVisualHelper.resolveType('חוסמי עורקים לעצירת דימום'),
        EquipmentVisualType.catTourniquet,
      );
      expect(
        EquipmentVisualHelper.resolveType('מזרק אפיפן'),
        EquipmentVisualType.epipenInjector,
      );
      expect(
        EquipmentVisualHelper.resolveType('שקיות נוזלים לעירוי (הרטמן 500 מל)'),
        EquipmentVisualType.ivFluidBag,
      );
      for (final item in DefaultEquipmentCatalog.items) {
        final name = item['name']?.toString() ?? '';
        expect(name, isNotEmpty);
        final visualType = EquipmentVisualHelper.resolveType(name);
        expect(visualType, isNotNull);
      }
    });

    test('DashboardMetrics serializes and deserializes for 0ms Cache-First startup', () {
      final original = DashboardMetrics(
        activeMedicalCases: 4,
        requiresAttentionCases: 2,
        missingEquipment: 3,
        totalEquipment: 49,
        expiringEquipment: 0,
        unverifiedMedics: 1,
        timelineEvents: [
          {'id': 't1', 'time': '08:00', 'title': 'מסדר בוקר', 'is_done': true},
        ],
        activeMedics: [
          {'id': 'm1', 'name': 'יגל', 'role': 'COMPANY_MEDIC', 'standby': true},
        ],
      );

      final restored = DashboardMetrics.fromMap(original.toMap());
      expect(restored.activeMedicalCases, 4);
      expect(restored.requiresAttentionCases, 2);
      expect(restored.missingEquipment, 3);
      expect(restored.totalEquipment, 49);
      expect(restored.timelineEvents.first['title'], 'מסדר בוקר');
      expect(restored.activeMedics.first['name'], 'יגל');
    });

    test('EquipmentPhotoCatalog maps all 15 real uploaded equipment photos accurately', () {
      expect(
        EquipmentPhotoCatalog.resolveBuiltInPhoto('קומבאט גז (Combat Gauze) לעצירת דימומים'),
        'assets/images/eq_combat_gauze.jpg',
      );
      expect(
        EquipmentPhotoCatalog.resolveBuiltInPhoto('תחבושת מיוחדת שעוצרת דימומים'),
        'assets/images/eq_combat_gauze.jpg',
      );
      expect(
        EquipmentPhotoCatalog.resolveBuiltInPhoto('גזה דחוסה לספיגה ועצירת דימומים'),
        'assets/images/eq_compressed_gauze.jpg',
      );
      expect(
        EquipmentPhotoCatalog.resolveBuiltInPhoto('תחבושת אישית First Care'),
        'assets/images/eq_first_care_bandage.jpg',
      );
      expect(
        EquipmentPhotoCatalog.resolveBuiltInPhoto('פלסטר מיקרופור (Micropore)'),
        'assets/images/eq_micropore.png',
      );
      expect(
        EquipmentPhotoCatalog.resolveBuiltInPhoto('משולשי בד לחבישה וקיבוע'),
        'assets/images/eq_triangular_bandage.png',
      );
      expect(
        EquipmentPhotoCatalog.resolveBuiltInPhoto('פדים סטריליים מבד גזה'),
        'assets/images/eq_gauze_pad.png',
      );
      expect(
        EquipmentPhotoCatalog.resolveBuiltInPhoto('פלסטרים קטנים לפצעים'),
        'assets/images/eq_plasters_box.png',
      );
      expect(
        EquipmentPhotoCatalog.resolveBuiltInPhoto('שמיכת מילוט'),
        'assets/images/eq_thermal_blanket.png',
      );
      expect(
        EquipmentPhotoCatalog.resolveBuiltInPhoto('תחבושת אלסטית 4 אינץ'),
        'assets/images/eq_elastic_bandage.png',
      );
      expect(
        EquipmentPhotoCatalog.resolveBuiltInPhoto('אגד גזה'),
        'assets/images/eq_gauze_roll.png',
      );
      expect(
        EquipmentPhotoCatalog.resolveBuiltInPhoto('כפפות רפואיות חד פעמיות'),
        'assets/images/eq_gloves.png',
      );
      expect(
        EquipmentPhotoCatalog.resolveBuiltInPhoto('מדחום למדידת חום'),
        'assets/images/eq_thermometer.png',
      );
      expect(
        EquipmentPhotoCatalog.resolveBuiltInPhoto('מד לחץ דם ידני עם סטטוסקופ'),
        'assets/images/eq_bp_cuff_stethoscope.png',
      );
      expect(
        EquipmentPhotoCatalog.resolveBuiltInPhoto('מכשיר לחמצן בדם (מד סטורציה)'),
        'assets/images/eq_pulse_oximeter.png',
      );
      expect(
        EquipmentPhotoCatalog.resolveBuiltInPhoto('צמרוני אוזניים / מקלוני צמר גפן'),
        'assets/images/eq_cotton_swabs.png',
      );
      expect(
        EquipmentPhotoCatalog.resolveBuiltInPhoto('מספריים רפואיים חזקים (מלע"כ)'),
        'assets/images/eq_trauma_shears.png',
      );
      expect(
        EquipmentPhotoCatalog.resolveBuiltInPhoto('צמר גפן לחיטוי וחבישה'),
        'assets/images/eq_cotton_wool.png',
      );
      expect(
        EquipmentPhotoCatalog.resolveBuiltInPhoto('ונפלון ירוק 18G'),
        'assets/images/eq_venflon_green_18g.png',
      );
      expect(
        EquipmentPhotoCatalog.resolveBuiltInPhoto('ונפלון כתום 14G'),
        'assets/images/eq_venflon_orange_14g.png',
      );
      expect(
        EquipmentPhotoCatalog.resolveBuiltInPhoto('תחבושת בטן'),
        'assets/images/eq_abdominal_bandage.png',
      );
      expect(
        EquipmentPhotoCatalog.resolveBuiltInPhoto('תמיסת הרטמן לעירוי'),
        'assets/images/eq_hartmann_solution.png',
      );
    });

    test('InventoryDispenseHelper blocks contraindicated medications based on soldier allergies', () {
      expect(
        InventoryDispenseHelper.getAllergyBlockReason('כדורי אופטלגין', 'חסר G6PD'),
        isNotNull,
      );
      expect(
        InventoryDispenseHelper.getAllergyBlockReason('כדורי אקמול רגילים (500 מג)', 'חסר G6PD'),
        isNull,
      );
      expect(
        InventoryDispenseHelper.getAllergyBlockReason('מוקסיפן 500 מ"ג', 'רגישות לפניצילין'),
        isNotNull,
      );
      expect(
        InventoryDispenseHelper.getAllergyBlockReason('נורופן / איבופרופן', 'NSAID'),
        isNotNull,
      );
      expect(
        InventoryDispenseHelper.getAllergyBlockReason('כדורי אקמול רגילים (500 מג)', 'אלרגיה לאקמול'),
        isNotNull,
      );
    });

    test('RedFlagsGuideScreen stays strictly within IDF field medic scope without hospital diagnoses', () {
      for (final topic in RedFlagsGuideScreen.topics) {
        final combined = [
          topic.title,
          topic.subtitle,
          ...topic.redFlags,
          ...topic.mandatoryChecks,
          topic.immediateAction,
        ].join(' ');
        expect(combined.contains('תסביב אשך'), isFalse);
      }
    });

    test('Equipment model supports vehicle, outpost, and patrol station categories cleanly', () {
      final cat = Equipment.stationCategoryFor('דוד סיור 1');
      expect(cat, 'עמדה/רכב::דוד סיור 1');

      final item = Equipment(
        id: 'eq_v1',
        name: 'חוסמי עורקים לעצירת דימום',
        category: cat,
        itemType: 'מתכלה',
        quantity: 2,
        minimumRequired: 2,
        status: 'IN_STOCK',
      );

      expect(item.isStationOrVehicle, isTrue);
      expect(item.stationName, 'דוד סיור 1');
      expect(item.isCompanyBox, isFalse);
      expect(item.isAnyMedicVest, isFalse);
    });
  });
}

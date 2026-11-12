import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chopel_app/core/services/outbreak_radar_service.dart';
import 'package:chopel_app/core/services/shift_handover_service.dart';
import 'package:chopel_app/core/services/p2p_sync_service.dart';
import 'package:chopel_app/core/services/follow_up_reminder_service.dart';
import 'package:chopel_app/models/medical_case.dart';
import 'package:chopel_app/models/soldier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Task 3: Outbreak Radar Service Tests', () {
    final soldier1 = Soldier(id: 's1', name: 'אבי כהן', platoon: 'מחלקה 1');
    final soldier2 = Soldier(id: 's2', name: 'יוסי לוי', platoon: 'מחלקה 1');
    final soldier3 = Soldier(id: 's3', name: 'דן ישראלי', platoon: 'מחלקה 1');
    final soldier4 = Soldier(id: 's4', name: 'אלון גולן', platoon: 'מחלקה 2');

    final soldiers = [soldier1, soldier2, soldier3, soldier4];

    test('Detects platoon-level cluster when >= 3 cases occur in same platoon within 72h', () {
      final now = DateTime.now();
      final cases = [
        MedicalCase(
          id: 'c1',
          soldierId: 's1',
          status: 'REQUIRES_ATTENTION',
          category: 'מערכת העיכול',
          createdDate: now.subtract(const Duration(hours: 10)).toIso8601String(),
        ),
        MedicalCase(
          id: 'c2',
          soldierId: 's2',
          status: 'REQUIRES_ATTENTION',
          category: 'מערכת העיכול',
          createdDate: now.subtract(const Duration(hours: 20)).toIso8601String(),
        ),
        MedicalCase(
          id: 'c3',
          soldierId: 's3',
          status: 'REQUIRES_ATTENTION',
          category: 'מערכת העיכול',
          createdDate: now.subtract(const Duration(hours: 30)).toIso8601String(),
        ),
      ];

      final alerts = OutbreakRadarService.detectOutbreaks(cases: cases, soldiers: soldiers, nowOverride: now);
      expect(alerts.isNotEmpty, isTrue);
      expect(alerts.first.category, 'מערכת העיכול');
      expect(alerts.first.platoon, 'מחלקה 1');
      expect(alerts.first.caseCount, 3);
      expect(alerts.first.affectedSoldierNames.length, 3);
    });

    test('Ignores cases outside the 72h rolling window', () {
      final now = DateTime.now();
      final cases = [
        MedicalCase(
          id: 'c1',
          soldierId: 's1',
          status: 'REQUIRES_ATTENTION',
          category: 'מערכת העיכול',
          createdDate: now.subtract(const Duration(hours: 80)).toIso8601String(), // 80h ago
        ),
        MedicalCase(
          id: 'c2',
          soldierId: 's2',
          status: 'REQUIRES_ATTENTION',
          category: 'מערכת העיכול',
          createdDate: now.subtract(const Duration(hours: 10)).toIso8601String(),
        ),
      ];

      final alerts = OutbreakRadarService.detectOutbreaks(cases: cases, soldiers: soldiers, nowOverride: now);
      expect(alerts.isEmpty, isTrue);
    });
  });

  group('Task 4: Shift Handover Service Tests', () {
    final soldier1 = Soldier(id: 's1', name: 'ישראל ישראלי', platoon: 'מחלקה 1', personalNumber: '8111222');
    final cases = [
      MedicalCase(
        id: 'c1',
        soldierId: 's1',
        status: 'REQUIRES_ATTENTION',
        description: 'חום גבוה וכאב ראש',
        createdDate: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      ),
    ];

    test('Generates structured shift handover report with pending cases and custom notes', () {
      final report = ShiftHandoverService.generateReport(
        cases: cases,
        soldiers: [soldier1],
        window: HandoverWindow.last24Hours,
        activeMedicsOnStandby: 2,
        totalMedicsCount: 4,
        customNotes: 'לוודא אספקת משחות בבוקר',
      );

      expect(report.contains('דוח חפיפת מרפאה פלוגתית'), isTrue);
      expect(report.contains('חיילים במעקב פעיל'), isTrue);
      expect(report.contains('ישראל ישראלי'), isTrue);
      expect(report.contains('חום גבוה וכאב ראש'), isTrue);
      expect(report.contains('לוודא אספקת משחות בבוקר'), isTrue);
      expect(report.contains('2 מתוך 4'), isTrue);
    });
  });

  group('Task 5: P2P Sync Service Tests', () {
    final soldier1 = Soldier(id: 's1', name: 'גלעד שרון', platoon: 'חפ"ק');
    final case1 = MedicalCase(
      id: 'case_p2p_1',
      soldierId: 's1',
      status: 'REQUIRES_ATTENTION',
      createdDate: '2026-11-12T10:00:00Z',
      description: 'פציעה ביד',
    );

    test('Generates valid base64 P2P payload and successfully merges incoming cases', () async {
      final payload = await P2pSyncService.generateExportPayload(
        cases: [case1],
        soldiers: [soldier1],
      );

      expect(payload.startsWith(P2pSyncService.packageHeader), isTrue);

      final result = await P2pSyncService.importAndMerge(payload);
      expect(result.success, isTrue);
      expect(result.casesMerged, 1);
    });
  });

  group('Task 6: Follow-Up Reminders Service Tests', () {
    test('Adds a reminder, retrieves pending list, and marks as complete with measured value', () async {
      final reminder = FollowUpReminder(
        id: 'rem_1',
        caseId: 'c_test_1',
        soldierId: 's_test_1',
        soldierName: 'אביאל שגב',
        type: 'מדידת חום חוזרת',
        dueTime: DateTime.now().subtract(const Duration(minutes: 5)), // already due
      );

      await FollowUpReminderService.addReminder(reminder);

      final pending = await FollowUpReminderService.getPendingReminders();
      expect(pending.length, 1);
      expect(pending.first.isOverdue, isTrue);

      await FollowUpReminderService.completeReminder('rem_1', measuredValue: '36.8°C');

      final remaining = await FollowUpReminderService.getPendingReminders();
      expect(remaining.isEmpty, isTrue);

      final all = await FollowUpReminderService.getReminders();
      expect(all.first.isCompleted, isTrue);
      expect(all.first.measuredValue, '36.8°C');
    });
  });
}


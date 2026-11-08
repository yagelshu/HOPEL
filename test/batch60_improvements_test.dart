import 'dart:typed_data';
import 'dart:ui' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:chopel_app/core/ai/medical_copilot_service.dart';
import 'package:chopel_app/core/utils/doctor_consult_helper.dart';
import 'package:chopel_app/core/utils/image_data_uri_helper.dart';
import 'package:chopel_app/models/medical_case.dart';
import 'package:chopel_app/models/soldier.dart';
import 'package:chopel_app/theme/app_theme.dart';

double _contrastRatio(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final bright = l1 > l2 ? l1 : l2;
  final dark = l1 > l2 ? l2 : l1;
  return (bright + 0.05) / (dark + 0.05);
}

void main() {
  group('MedicalCopilotService clinical rules & allergy cross-check', () {
    final service = MedicalCopilotService();

    test('responds promptly without artificial 2s delay and includes empty complaint allergy alert', () async {
      final sw = Stopwatch()..start();
      final res = await service.analyzeSymptoms('   ', allergies: 'G6PD');
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(500));
      expect(res['diagnosis'], 'לא סופק תיאור מספיק');
      expect((res['allergyWarnings'] as List).first.toString(), contains('G6PD'));
    });

    test('G6PD sensitivity removes Optalgin and adds explicit safety warning', () async {
      final res = await service.analyzeSymptoms('כאב ראש וחום גבוה', allergies: 'G6PD');
      final meds = List<String>.from(res['medications'] as List);
      final warnings = List<String>.from(res['allergyWarnings'] as List);

      expect(meds.any((m) => m.contains('אופטלגין')), isFalse);
      expect(meds.any((m) => m.contains('אקמול')), isTrue);
      expect(warnings.any((w) => w.contains('G6PD') && w.contains('אופטלגין')), isTrue);
    });

    test('NSAID sensitivity removes Ibuprofen and Voltaren', () async {
      final res = await service.analyzeSymptoms('כאבי גב ושרירים', allergies: 'רגישות ל-NSAID');
      final meds = List<String>.from(res['medications'] as List);
      final warnings = List<String>.from(res['allergyWarnings'] as List);

      expect(meds.any((m) => m.contains('איבופרופן') || m.contains('וולטרן')), isFalse);
      expect(warnings.any((w) => w.contains('NSAID')), isTrue);
    });

    test('Penicillin sensitivity removes beta-lactam antibiotic recommendations', () async {
      final res = await service.analyzeSymptoms('כאבי גרון', allergies: 'פניצילין');
      final meds = List<String>.from(res['medications'] as List);
      final warnings = List<String>.from(res['allergyWarnings'] as List);

      expect(meds.any((m) => m.contains('פניצילין') || m.contains('מוקסיפן')), isFalse);
      expect(meds.any((m) => m.contains('לכסניות')), isTrue);
      expect(warnings.any((w) => w.contains('פניצילין')), isTrue);
    });

    test('Paracetamol sensitivity removes Acamol and warns', () async {
      final res = await service.analyzeSymptoms('כאב ראש', allergies: 'אקמול / פראצטמול');
      final meds = List<String>.from(res['medications'] as List);
      final warnings = List<String>.from(res['allergyWarnings'] as List);

      expect(meds.any((m) => m.contains('אקמול')), isFalse);
      expect(warnings.any((w) => w.contains('פראצטמול')), isTrue);
    });

    test('Other allergies still surface reminder alert without blocking safe meds', () async {
      final res = await service.analyzeSymptoms('חום/צינון', allergies: 'שומשום');
      final warnings = List<String>.from(res['allergyWarnings'] as List);

      expect(warnings.length, 1);
      expect(warnings.first, contains('שומשום'));
    });
  });

  group('ImageDataUriHelper', () {
    test('encodes bytes to base64 Data URI and handles empty bytes', () {
      expect(ImageDataUriHelper.encodeBytesToDataUri(Uint8List(0)), isEmpty);
      final uri = ImageDataUriHelper.encodeBytesToDataUri(
        Uint8List.fromList([1, 2, 3, 4]),
        mimeType: 'image/png',
      );
      expect(uri, startsWith('data:image/png;base64,'));
    });

    test('infers MIME types accurately from filenames', () {
      expect(ImageDataUriHelper.inferMimeType('photo.png'), 'image/png');
      expect(ImageDataUriHelper.inferMimeType('photo.WEBP'), 'image/webp');
      expect(ImageDataUriHelper.inferMimeType('photo.jpg'), 'image/jpeg');
      expect(ImageDataUriHelper.inferMimeType(null), 'image/jpeg');
    });

    test('identifies local filesystem paths vs Web/Data/Remote URIs', () {
      expect(ImageDataUriHelper.isLocalFilesystemPath(null), isFalse);
      expect(ImageDataUriHelper.isLocalFilesystemPath(''), isFalse);
      expect(ImageDataUriHelper.isLocalFilesystemPath('data:image/jpeg;base64,abc'), isFalse);
      expect(ImageDataUriHelper.isLocalFilesystemPath('blob:https://example.com/123'), isFalse);
      expect(ImageDataUriHelper.isLocalFilesystemPath('https://cdn.example.com/a.jpg'), isFalse);
      expect(ImageDataUriHelper.isLocalFilesystemPath('/storage/emulated/0/a.jpg'), isTrue);
      expect(ImageDataUriHelper.isLocalFilesystemPath(r'C:\Users\medic\photo.jpg'), isTrue);
    });
  });

  group('DoctorConsultHelper', () {
    test('formats Israeli phone numbers for WhatsApp', () {
      expect(DoctorConsultHelper.formatPhoneForWhatsApp('050-123-4567'), '972501234567');
      expect(DoctorConsultHelper.formatPhoneForWhatsApp('+972 52 987 6543'), '972529876543');
    });

    test('builds complete clinical message with PN, platoon, allergies and photo note', () {
      final soldier = Soldier(
        id: 's1',
        name: 'דני כהן',
        personalNumber: '8877665',
        platoon: '2',
        allergies: 'G6PD',
      );
      final medCase = MedicalCase(
        id: 'c1',
        soldierId: 's1',
        status: 'REQUIRES_ATTENTION',
        description: 'חום 38.7 ופריחה',
        createdDate: '2026-11-08T10:00:00Z',
        category: 'בדיקת רופא',
        severity: 'דחוף',
        imagePath: 'data:image/jpeg;base64,abc',
      );

      final msg = DoctorConsultHelper.buildMedicalCaseMessage(
        medicalCase: medCase,
        soldier: soldier,
      );

      expect(msg, contains('דני כהן'));
      expect(msg, contains('מ.א 8877665'));
      expect(msg, contains('מחלקה 2'));
      expect(msg, contains('🚨 *רגישות ידועה:* G6PD'));
      expect(msg, contains('חום 38.7 ופריחה'));
      expect(msg, contains('בטיפול / מעקב'));
      expect(msg, contains('📷'));
    });
  });

  group('AppTheme contrast verification across Dark & Light modes', () {
    tearDown(() => AppTheme.setDarkMode());

    test('Dark Mode primaryGreen and warningAmber foregrounds meet WCAG AA (>= 4.5:1)', () {
      AppTheme.setDarkMode();
      expect(_contrastRatio(AppTheme.primaryGreen, AppTheme.onPrimaryGreen), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(AppTheme.warningAmber, AppTheme.onWarningAmber), greaterThanOrEqualTo(4.5));
    });

    test('Light Mode primaryGreen and warningAmber foregrounds meet WCAG AA (>= 4.5:1)', () {
      AppTheme.setLightMode();
      expect(_contrastRatio(AppTheme.primaryGreen, AppTheme.onPrimaryGreen), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(AppTheme.warningAmber, AppTheme.onWarningAmber), greaterThanOrEqualTo(4.5));
    });
  });
}


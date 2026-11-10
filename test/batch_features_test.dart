import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:chopel_app/core/utils/image_data_uri_helper.dart';
import 'package:chopel_app/features/learning/medication_guide_screen.dart';
import 'package:chopel_app/models/medical_case.dart';
import 'package:chopel_app/models/soldier.dart';

void main() {
  group('Task 4: Automatic Image Compression & Helper Tests', () {
    test('ImageDataUriHelper correctly infers mime types', () {
      expect(ImageDataUriHelper.inferMimeType('wound.png'), 'image/png');
      expect(ImageDataUriHelper.inferMimeType('photo.webp'), 'image/webp');
      expect(ImageDataUriHelper.inferMimeType('rash.jpg'), 'image/jpeg');
      expect(ImageDataUriHelper.inferMimeType('skin.jpeg'), 'image/jpeg');
      expect(ImageDataUriHelper.inferMimeType(''), 'image/jpeg');
      expect(ImageDataUriHelper.inferMimeType(null), 'image/jpeg');
    });

    test('ImageDataUriHelper encodes bytes into standard Data URI', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final uri = ImageDataUriHelper.encodeBytesToDataUri(bytes, mimeType: 'image/jpeg');
      expect(uri.startsWith('data:image/jpeg;base64,'), isTrue);
    });

    test('CompressionResult formats sizes accurately', () {
      const result = CompressionResult(
        dataUri: 'data:image/jpeg;base64,abc',
        compressedBytesLength: 85 * 1024,
        mimeType: 'image/jpeg',
      );
      expect(result.kb, 85);
      expect(result.sizeLabel, '85 KB');
    });
  });

  group('Task 2: Field Medication Guide & Dosage Calculator Tests', () {
    test('Medication database contains key combat and reserve medications', () {
      const meds = MedicationGuideScreen.medications;
      expect(meds.isNotEmpty, isTrue);

      final acamol = meds.firstWhere((m) => m.id == 'acamol');
      expect(acamol.standardSingleDoseMg, 1000);
      expect(acamol.maxDailyMg, 4000);
      expect(acamol.isG6pdContraindicated, isFalse);

      final optalgin = meds.firstWhere((m) => m.id == 'optalgin');
      expect(optalgin.isG6pdContraindicated, isTrue);
      expect(optalgin.standardSingleDoseMg, 1000);

      final nurofen = meds.firstWhere((m) => m.id == 'nurofen');
      expect(nurofen.isNsaidContraindicated, isTrue);
      expect(nurofen.isAsthmaContraindicated, isTrue);
      expect(nurofen.isUlcerContraindicated, isTrue);

      final silverol = meds.firstWhere((m) => m.id == 'silverol');
      expect(silverol.isG6pdContraindicated, isTrue);

      final txa = meds.firstWhere((m) => m.id == 'txa');
      expect(txa.requiresDoctorAuth, isTrue);

      final actiq = meds.firstWhere((m) => m.id == 'actiq');
      expect(actiq.requiresDoctorAuth, isTrue);
    });
  });

  group('Task 1: Soldier Medical History Logic Tests', () {
    final soldier1 = Soldier(id: 's1', name: 'ישראל ישראלי', personalNumber: '8111222');
    final soldier2 = Soldier(id: 's2', name: 'משה כהן', personalNumber: '7333444');

    final case1 = MedicalCase(
      id: 'c1',
      soldierId: 's1',
      status: 'REQUIRES_ATTENTION',
      createdDate: '2026-11-01T10:00:00Z',
      description: 'נקע בקרסול ימין',
      imagePath: '[{"path":"data:image/jpeg;base64,111","complaintTag":"נקע"}]',
    );

    final case2 = MedicalCase(
      id: 'c2',
      soldierId: 's1',
      status: 'COMPLETED',
      createdDate: '2026-11-05T14:00:00Z',
      description: 'חום וכאב גרון',
      imagePath: null,
    );

    final case3 = MedicalCase(
      id: 'c3',
      soldierId: 's2',
      status: 'COMPLETED',
      createdDate: '2026-11-06T09:00:00Z',
      description: 'שפשפת',
      imagePath: null,
    );

    final allCases = [case1, case2, case3];

    test('Filters cases correctly for a specific soldier', () {
      final s1Cases = allCases.where((c) => c.soldierId == soldier1.id).toList();
      expect(s1Cases.length, 2);
      expect(s1Cases.map((c) => c.id), containsAll(['c1', 'c2']));

      final s2Cases = allCases.where((c) => c.soldierId == soldier2.id).toList();
      expect(s2Cases.length, 1);
      expect(s2Cases.first.id, 'c3');
    });

    test('Computes active, completed, and photo metrics correctly', () {
      final s1Cases = allCases.where((c) => c.soldierId == soldier1.id).toList();
      final active = s1Cases.where((c) => c.status != 'COMPLETED' && c.status != 'טופל').length;
      final completed = s1Cases.where((c) => c.status == 'COMPLETED' || c.status == 'טופל').length;
      final totalPhotos = s1Cases.fold<int>(0, (sum, c) => sum + c.photos.length);

      expect(active, 1);
      expect(completed, 1);
      expect(totalPhotos, 1);
      expect(s1Cases.first.photos.first.complaintTag, 'נקע');
    });
  });
}

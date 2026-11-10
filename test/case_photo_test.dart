import 'package:flutter_test/flutter_test.dart';
import 'package:chopel_app/models/medical_case.dart';

void main() {
  group('CasePhoto and MedicalCase.photos', () {
    test('handles null imagePath gracefully', () {
      final c = MedicalCase(
        id: '1',
        soldierId: 's1',
        status: 'OPEN',
        createdDate: '2026-11-10',
        imagePath: null,
      );
      expect(c.photos, isEmpty);
      expect(MedicalCase.encodePhotos([]), isNull);
    });

    test('backward compatibility: parses legacy single imagePath string', () {
      final c = MedicalCase(
        id: '2',
        soldierId: 's1',
        status: 'OPEN',
        createdDate: '2026-11-10',
        imagePath: 'data:image/jpeg;base64,abc123legacy',
      );
      expect(c.photos.length, 1);
      expect(c.photos.first.path, 'data:image/jpeg;base64,abc123legacy');
      expect(c.photos.first.complaintTag, isNull);
    });

    test('encodes and decodes multiple photos with complaint tags', () {
      final originalPhotos = [
        CasePhoto(path: 'data:image/jpeg;base64,photo1', complaintTag: 'שפשפות'),
        CasePhoto(path: 'data:image/jpeg;base64,photo2', complaintTag: 'פריחה/פטרת'),
        CasePhoto(path: 'data:image/jpeg;base64,photo3', complaintTag: null),
      ];

      final encoded = MedicalCase.encodePhotos(originalPhotos);
      expect(encoded, isNotNull);
      expect(encoded!.startsWith('['), isTrue);

      final c = MedicalCase(
        id: '3',
        soldierId: 's1',
        status: 'OPEN',
        createdDate: '2026-11-10',
        imagePath: encoded,
      );

      expect(c.photos.length, 3);
      expect(c.photos[0].path, 'data:image/jpeg;base64,photo1');
      expect(c.photos[0].complaintTag, 'שפשפות');

      expect(c.photos[1].path, 'data:image/jpeg;base64,photo2');
      expect(c.photos[1].complaintTag, 'פריחה/פטרת');

      expect(c.photos[2].path, 'data:image/jpeg;base64,photo3');
      expect(c.photos[2].complaintTag, isNull);
    });

    test('CasePhoto.copyWith allows updating complaintTag', () {
      final p1 = CasePhoto(path: 'photo1', complaintTag: 'שפשפות');
      final p2 = p1.copyWith(complaintTag: 'כוויות');
      expect(p2.complaintTag, 'כוויות');
      expect(p2.path, 'photo1');

      final p3 = p2.copyWith(clearTag: true);
      expect(p3.complaintTag, isNull);
    });
  });
}

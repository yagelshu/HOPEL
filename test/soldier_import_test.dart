import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:chopel_app/core/services/soldier_import_service.dart';

void main() {
  group('SoldierImportService Tests', () {
    test('guessMapping correctly detects Hebrew column headers', () {
      final headers = ['שם מלא', 'מספר אישי', 'טלפון', 'מחלקה'];
      final mapping = SoldierImportService.guessMapping(headers);

      expect(mapping, [
        SoldierField.fullName,
        SoldierField.personalNumber,
        SoldierField.phone,
        SoldierField.platoon,
      ]);
    });

    test('guessMapping detects variants: מ.א, נייד, צוות, פרטי ומשפחה', () {
      final headers = ['שם פרטי', 'שם משפחה', 'מ"א', 'נייד', 'צוות'];
      final mapping = SoldierImportService.guessMapping(headers);

      expect(mapping, [
        SoldierField.firstName,
        SoldierField.lastName,
        SoldierField.personalNumber,
        SoldierField.phone,
        SoldierField.platoon,
      ]);
    });

    test('apply converts parsed table rows to ImportedSoldier objects', () {
      final table = ImportTable(
        ['שם מלא', 'מספר אישי', 'טלפון', 'מחלקה'],
        [
          ['ישראל ישראלי', '8123456', '050-1234567', '1'],
          ['יוסי כהן', '8987654', '052-7654321', '2'],
          ['', '1234567', '', ''], // Should be skipped (no name)
        ],
      );

      final mapping = [
        SoldierField.fullName,
        SoldierField.personalNumber,
        SoldierField.phone,
        SoldierField.platoon,
      ];

      final result = SoldierImportService.apply(table, mapping);

      expect(result.length, 2);
      expect(result[0].name, 'ישראל ישראלי');
      expect(result[0].personalNumber, '8123456');
      expect(result[0].phone, '050-1234567');
      expect(result[0].platoon, '1');

      expect(result[1].name, 'יוסי כהן');
      expect(result[1].personalNumber, '8987654');
    });

    test('parse correctly decodes CSV string with Hebrew data', () {
      const csv = 'שם מלא,מספר אישי,טלפון,מחלקה\nרועי אברהם,7654321,054-9998877,חפ"ק\n';
      final bytes = Uint8List.fromList(utf8.encode(csv));

      final table = SoldierImportService.parse(bytes, 'soldiers.csv');

      expect(table.headers, ['שם מלא', 'מספר אישי', 'טלפון', 'מחלקה']);
      expect(table.rows.length, 1);
      expect(table.rows[0][0], 'רועי אברהם');
      expect(table.rows[0][1], '7654321');
      expect(table.rows[0][3], 'חפ"ק');
    });
  });
}

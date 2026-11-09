import 'package:flutter_test/flutter_test.dart';
import 'package:chopel_app/core/services/soldier_import_service.dart';
import 'package:chopel_app/models/soldier.dart';

void main() {
  group('SoldierImportService.reconcile', () {
    test('matches 91 existing soldiers without P.N. by name and detects 5 new soldiers', () {
      // 91 existing soldiers in app without P.N.
      final existingSoldiers = List.generate(
        91,
        (i) => Soldier(
          id: 'existing_$i',
          name: 'חייל מספר $i',
          personalNumber: null,
          platoon: 'מחלקה 1',
        ),
      );

      // 96 imported soldiers from Excel, all with P.N. (91 existing names + 5 brand new soldiers)
      final importedSoldiers = [
        ...List.generate(
          91,
          (i) => ImportedSoldier(
            name: 'חייל מספר $i',
            personalNumber: '88000$i',
            platoon: '1',
            phone: '05012340$i',
          ),
        ),
        ...List.generate(
          5,
          (i) => ImportedSoldier(
            name: 'חייל חדש $i',
            personalNumber: '99000$i',
            platoon: '2',
            phone: '05212340$i',
          ),
        ),
      ];

      final recon = SoldierImportService.reconcile(
        imported: importedSoldiers,
        existingInDb: existingSoldiers,
      );

      expect(recon.toUpdate.length, 91);
      expect(recon.newSoldiers.length, 5);
      expect(recon.existingNotInImport.length, 0);

      // Verify the 5 new soldiers are indeed the new ones
      expect(recon.newSoldiers.map((s) => s.name), contains('חייל חדש 0'));
      expect(recon.newSoldiers.map((s) => s.name), contains('חייל חדש 4'));

      // Verify that matched soldiers have correct existing IDs
      final match0 = recon.toUpdate.firstWhere((m) => m.imported.name == 'חייל מספר 0');
      expect(match0.existing.id, 'existing_0');
      expect(match0.imported.personalNumber, '880000');
    });

    test('matches soldiers with minor whitespace, punctuation, and phone numbers', () {
      final existing = [
        Soldier(id: 's1', name: 'אביאל  שבתאי', personalNumber: null, phoneNumber: '052-3865082'),
        Soldier(id: 's2', name: 'דני כהן (חובש)', personalNumber: null),
        Soldier(id: 's3', name: 'יוסי לוי', personalNumber: null, phoneNumber: '0541112233'),
      ];

      final imported = [
        ImportedSoldier(name: 'אביאל שבתאי', personalNumber: '8111111'),
        ImportedSoldier(name: 'דני כהן', personalNumber: '8222222'),
        ImportedSoldier(name: 'יוסף לוי', personalNumber: '8333333', phone: '054-111-2233'), // matched by phone
        ImportedSoldier(name: 'חייל לא מוכר', personalNumber: '8444444'),
      ];

      final recon = SoldierImportService.reconcile(
        imported: imported,
        existingInDb: existing,
      );

      expect(recon.toUpdate.length, 3);
      expect(recon.newSoldiers.length, 1);
      expect(recon.newSoldiers.first.name, 'חייל לא מוכר');
    });

    test('detects soldiers in app that were NOT in the Excel file', () {
      final existing = [
        Soldier(id: 's1', name: 'חייל א', personalNumber: '111'),
        Soldier(id: 's2', name: 'חייל ב שנשאר באפליקציה אך הושמט מהאקסל', personalNumber: '222'),
      ];

      final imported = [
        ImportedSoldier(name: 'חייל א', personalNumber: '111'),
      ];

      final recon = SoldierImportService.reconcile(
        imported: imported,
        existingInDb: existing,
      );

      expect(recon.toUpdate.length, 1);
      expect(recon.newSoldiers.length, 0);
      expect(recon.existingNotInImport.length, 1);
      expect(recon.existingNotInImport.first.name, 'חייל ב שנשאר באפליקציה אך הושמט מהאקסל');
    });

    test('matches reversed Hebrew names (last-name first vs first-name last)', () {
      final existing = [
        Soldier(id: 's1', name: 'יוסי כהן', personalNumber: null),
        Soldier(id: 's2', name: 'אביאל שבתאי', personalNumber: null),
        Soldier(id: 's3', name: 'יגל שולמן', personalNumber: null),
        Soldier(id: 's4', name: 'אהרון מהרט', personalNumber: null),
      ];

      // Inverted in military roster: Last Name, First Name
      final imported = [
        ImportedSoldier(name: 'כהן יוסי', personalNumber: '8111111'),
        ImportedSoldier(name: 'שבתאי אביאל', personalNumber: '8222222'),
        ImportedSoldier(name: 'שולמן יגל', personalNumber: '8333333'),
        ImportedSoldier(name: 'מהרט אהרון', personalNumber: '8444444'),
      ];

      final recon = SoldierImportService.reconcile(
        imported: imported,
        existingInDb: existing,
      );

      expect(recon.toUpdate.length, 4);
      expect(recon.newSoldiers.length, 0);
      expect(recon.toUpdate[0].existing.id, 's1');
      expect(recon.toUpdate[1].existing.id, 's2');
      expect(recon.toUpdate[2].existing.id, 's3');
      expect(recon.toUpdate[3].existing.id, 's4');
    });

    test('matches with hidden unicode marks, numbering, and military ranks', () {
      final existing = [
        Soldier(id: 's1', name: 'יוסי כהן', personalNumber: null),
        Soldier(id: 's2', name: 'אביאל שבתאי', personalNumber: null),
        Soldier(id: 's3', name: 'אהרון מהרט', personalNumber: null),
        Soldier(id: 's4', name: 'אוהד גריבסקי', personalNumber: null),
      ];

      final imported = [
        ImportedSoldier(name: '\u200Eכהן יוסי', personalNumber: '8111111'), // LRM + inverted
        ImportedSoldier(name: '1. אביאל שבתאי', personalNumber: '8222222'), // Numbered
        ImportedSoldier(name: '02) מהרט אהרון', personalNumber: '8333333'), // Numbered + inverted
        ImportedSoldier(name: 'סמ"ר אוהד גריבסקי', personalNumber: '8444444'), // Rank
      ];

      final recon = SoldierImportService.reconcile(
        imported: imported,
        existingInDb: existing,
      );

      expect(recon.toUpdate.length, 4);
      expect(recon.newSoldiers.length, 0);
    });

    test('parsePastedText splits single-column lines with name and P.N. into 2 columns', () {
      const text = '''
כהן יוסי 8123456
8234567 - לוי דניאל
שבתאי אביאל 8345678
''';
      final table = SoldierImportService.parsePastedText(text);
      expect(table.headers.length, 2);
      final mapping = SoldierImportService.smartGuessMapping(table);
      final applied = SoldierImportService.apply(table, mapping);

      expect(applied.length, 3);
      expect(applied[0].name, 'כהן יוסי');
      expect(applied[0].personalNumber, '8123456');

      expect(applied[1].name, 'לוי דניאל');
      expect(applied[1].personalNumber, '8234567');

      expect(applied[2].name, 'שבתאי אביאל');
      expect(applied[2].personalNumber, '8345678');
    });

    test('apply automatically extracts 5-9 digit P.N. embedded inside single name column', () {
      final table = ImportTable(
        ['שם מלא'],
        [
          ['יוסי כהן 8123456'],
          ['8234567 - ישראל ישראלי'],
          ['דני לוי (מ.א 8345678)'],
          ['חייל ללא מספר'],
        ],
      );

      final mapping = [SoldierField.fullName];
      final applied = SoldierImportService.apply(table, mapping);

      expect(applied.length, 4);
      expect(applied[0].name, 'יוסי כהן');
      expect(applied[0].personalNumber, '8123456');

      expect(applied[1].name, 'ישראל ישראלי');
      expect(applied[1].personalNumber, '8234567');

      expect(applied[2].name, 'דני לוי');
      expect(applied[2].personalNumber, '8345678');

      expect(applied[3].name, 'חייל ללא מספר');
      expect(applied[3].personalNumber, isNull);
    });
  });
}


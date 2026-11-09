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
  });
}

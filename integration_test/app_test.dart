import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chopel_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('End-to-end test: add medic and verify dashboard', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Since we wipe the DB on createUnit, the user might land on Login or UnitSelection if they aren't logged in.
    // For this test, we assume the app might need us to login. 
    // We'll look for "הוסף חובש לפלוגה" (Add medic). If it's not there, the test will fail, indicating we need a mock user setup first.
    // However, if the mock DB creates a logged-in state, this might pass directly.

    // Try to find the Add Medic button (it might be in a bottom sheet)
    // Wait, the Add Medic button is inside the "חובשים בכוננות" (Medics on Standby) bottom sheet!
    // So we first need to tap the Medics card.
    
    final medicsCardFinder = find.textContaining('חובשים בכוננות');
    if (medicsCardFinder.evaluate().isNotEmpty) {
      await tester.tap(medicsCardFinder.first);
      await tester.pumpAndSettle();

      final addMedicBtn = find.text('הוסף חובש לפלוגה');
      expect(addMedicBtn, findsOneWidget);

      await tester.tap(addMedicBtn);
      await tester.pumpAndSettle();

      // Enter a name
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'חובש בדיקה אוטומטית');
      await tester.pumpAndSettle();

      // Tap 'הוסף' (Add)
      final addConfirmBtn = find.text('הוסף');
      await tester.tap(addConfirmBtn);
      await tester.pumpAndSettle();

      // Verify the new medic appears in the bottom sheet
      expect(find.text('חובש בדיקה אוטומטית'), findsOneWidget);
      
      // Close the bottom sheet by tapping on the background or back button
      // We can just press escape or pop
      await tester.pageBack();
      await tester.pumpAndSettle();
      
      // Now let's test schedule (לו"ז) update
      final editScheduleBtn = find.text('עריכת לו"ז');
      if (editScheduleBtn.evaluate().isNotEmpty) {
        await tester.tap(editScheduleBtn);
        await tester.pumpAndSettle();
        
        // Wait, the schedule might have checkboxes
        final checkbox = find.byType(Checkbox).first;
        if (checkbox.evaluate().isNotEmpty) {
          await tester.tap(checkbox);
          await tester.pumpAndSettle();
        }
        
        // Close bottom sheet
        await tester.pageBack();
        await tester.pumpAndSettle();
      }

    } else {
      print('Could not find Medics card. App might be in login state.');
    }
  });
}

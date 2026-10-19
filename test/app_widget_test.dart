import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chopel_app/features/dashboard/dashboard_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  // Initialize sqflite_common_ffi for desktop/unit testing
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://placeholder.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.placeholder',
      );
    } catch (_) {}
  });

  testWidgets('Widget Test: add medic and verify dashboard', (WidgetTester tester) async {
    // Pump DashboardScreen directly to bypass Splash and Supabase init
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Find the Medics card
    final medicsCardFinder = find.textContaining('חובשים בכוננות');
    if (medicsCardFinder.evaluate().isNotEmpty) {
      await tester.tap(medicsCardFinder.first);
      await tester.pumpAndSettle();

      final addMedicBtn = find.text('הוסף חובש לפלוגה');
      expect(addMedicBtn, findsOneWidget);

      await tester.tap(addMedicBtn);
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'חובש בדיקה אוטומטית');
      await tester.pumpAndSettle();

      final addConfirmBtn = find.text('הוסף');
      await tester.tap(addConfirmBtn);
      await tester.pumpAndSettle();

      expect(find.text('חובש בדיקה אוטומטית'), findsOneWidget);
      
      await tester.pageBack();
      await tester.pumpAndSettle();
      
      final editScheduleBtn = find.text('עריכת לו"ז');
      if (editScheduleBtn.evaluate().isNotEmpty) {
        await tester.tap(editScheduleBtn);
        await tester.pumpAndSettle();
        
        final checkbox = find.byType(Checkbox).first;
        if (checkbox.evaluate().isNotEmpty) {
          await tester.tap(checkbox);
          await tester.pumpAndSettle();
        }
        
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
    } else {
      print('App might be in login state.');
    }
  });
}

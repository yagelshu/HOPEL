import 'package:flutter_test/flutter_test.dart';
import 'package:chopel_app/core/utils/platoon_helper.dart';

void main() {
  group('PlatoonHelper', () {
    test('normalizes pure digits to canonical מחלקה X', () {
      expect(PlatoonHelper.normalize('1'), 'מחלקה 1');
      expect(PlatoonHelper.normalize('2'), 'מחלקה 2');
      expect(PlatoonHelper.normalize('3'), 'מחלקה 3');
      expect(PlatoonHelper.normalize(' 4 '), 'מחלקה 4');
    });

    test('preserves canonical מחלקה X without duplicating', () {
      expect(PlatoonHelper.normalize('מחלקה 1'), 'מחלקה 1');
      expect(PlatoonHelper.normalize('מחלקה 2'), 'מחלקה 2');
      expect(PlatoonHelper.normalize('מחלקה1'), 'מחלקה 1');
    });

    test('strips repetitive redundant מחלקה prefixes', () {
      expect(PlatoonHelper.normalize('מחלקה מחלקה 1'), 'מחלקה 1');
      expect(PlatoonHelper.normalize('מחלקה מחלקה 2'), 'מחלקה 2');
      expect(PlatoonHelper.normalize('מחלקה מחלקה מחלקה 3'), 'מחלקה 3');
      expect(PlatoonHelper.normalize('מחלקה מפלג'), 'מפלג');
    });

    test('preserves special company units without forcing מחלקה prefix', () {
      expect(PlatoonHelper.normalize('מפלג'), 'מפלג');
      expect(PlatoonHelper.normalize('חפ"ק'), 'חפ"ק');
      expect(PlatoonHelper.normalize('רתק'), 'רתק');
    });

    test('extractPlatoons unifies 3 and מחלקה 3 into a single canonical option', () {
      final list = [
        {'p': 'מחלקה 1'},
        {'p': '1'},
        {'p': 'מחלקה 2'},
        {'p': '3'},
        {'p': 'מחלקה 3'},
        {'p': 'מפלג'},
        {'p': 'מחלקה מפלג'},
      ];

      final extracted = PlatoonHelper.extractPlatoons(list, (m) => m['p'] as String);

      expect(extracted, contains('הכל'));
      expect(extracted, contains('מפלג'));
      expect(extracted, contains('מחלקה 1'));
      expect(extracted, contains('מחלקה 2'));
      expect(extracted, contains('מחלקה 3'));

      // Ensure no raw '3' or '1' exists
      expect(extracted.contains('3'), isFalse);
      expect(extracted.contains('1'), isFalse);

      // Ensure no duplicates
      expect(extracted.where((p) => p == 'מחלקה 3').length, 1);
      expect(extracted.where((p) => p == 'מפלג').length, 1);
    });

    test('matches correctly under normalization', () {
      expect(PlatoonHelper.matches('3', 'מחלקה 3'), isTrue);
      expect(PlatoonHelper.matches('מחלקה מחלקה 2', '2'), isTrue);
      expect(PlatoonHelper.matches('מחלקה מפלג', 'מפלג'), isTrue);
      expect(PlatoonHelper.matches('מחלקה 1', 'מחלקה 2'), isFalse);
    });
  });
}


import 'dart:convert';
import 'dart:typed_data';

import 'package:chopel_app/core/services/xlsx_reader.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fields a spreadsheet column can be mapped to.
enum SoldierField { ignore, fullName, firstName, lastName, personalNumber, phone, platoon }

extension SoldierFieldLabel on SoldierField {
  String get label => switch (this) {
        SoldierField.ignore => 'התעלם',
        SoldierField.fullName => 'שם מלא',
        SoldierField.firstName => 'שם פרטי',
        SoldierField.lastName => 'שם משפחה',
        SoldierField.personalNumber => 'מספר אישי',
        SoldierField.phone => 'טלפון',
        SoldierField.platoon => 'מחלקה',
      };
}

/// Raw table read from a file: header row + data rows (all strings).
class ImportTable {
  final List<String> headers;
  final List<List<String>> rows;
  ImportTable(this.headers, this.rows);
}

/// A parsed soldier ready to be saved.
class ImportedSoldier {
  final String name;
  final String? personalNumber;
  final String? phone;
  final String? platoon;
  ImportedSoldier({required this.name, this.personalNumber, this.phone, this.platoon});

  Map<String, dynamic> toRow(String unitId) => {
        'name': name,
        'personal_number': personalNumber,
        'phone_number': phone,
        'platoon': platoon,
        'unit_id': unitId,
      };
}

class ImportResult {
  final int saved;
  final int skipped;
  ImportResult(this.saved, this.skipped);
}

/// Pure business logic for importing a company roster. No UI here.
class SoldierImportService {
  /// Reads .xlsx / .csv bytes into a table. Throws [FormatException] on bad input.
  static ImportTable parse(Uint8List bytes, String fileName) {
    final lower = fileName.toLowerCase();
    final List<List<String>> all;
    if (lower.endsWith('.csv') || lower.endsWith('.txt')) {
      all = _parseCsv(utf8.decode(bytes, allowMalformed: true));
    } else if (lower.endsWith('.xlsx')) {
      all = XlsxReader.readFirstSheet(bytes);
    } else {
      throw const FormatException('יש לבחור קובץ ‎.xlsx או ‎.csv (קבצי ‎.xls ישנים - שמור מחדש כ-xlsx)');
    }

    final nonEmpty = all.where((r) => r.any((c) => c.trim().isNotEmpty)).toList();
    if (nonEmpty.isEmpty) throw const FormatException('לא נמצאו נתונים בקובץ');

    final width = nonEmpty.map((r) => r.length).reduce((a, b) => a > b ? a : b);
    List<String> pad(List<String> r) => [...r, ...List.filled(width - r.length, '')];

    final headers = pad(nonEmpty.first).map((h) => h.trim()).toList();
    final rows = nonEmpty.skip(1).map(pad).toList();
    return ImportTable(headers, rows);
  }

  /// Guesses a mapping from header names (Hebrew + English).
  static List<SoldierField> guessMapping(List<String> headers) {
    final used = <SoldierField>{};
    SoldierField guess(String h) {
      final s = h.replaceAll(RegExp(r'[\s"\x27׳״._-]'), '').toLowerCase();
      SoldierField? f;
      if (s.contains('אישי') || s == 'מא' || s.contains('personal') || s.contains('mispar')) {
        f = SoldierField.personalNumber;
      } else if (s.contains('טלפון') || s.contains('נייד') || s.contains('פלאפון') || s.contains('phone')) {
        f = SoldierField.phone;
      } else if (s.contains('מחלקה') || s.contains('צוות') || s.contains('platoon')) {
        f = SoldierField.platoon;
      } else if (s.contains('פרטי') || s.contains('first')) {
        f = SoldierField.firstName;
      } else if (s.contains('משפחה') || s.contains('last')) {
        f = SoldierField.lastName;
      } else if (s.contains('שם') || s.contains('name')) {
        f = SoldierField.fullName;
      }
      if (f == null || used.contains(f)) return SoldierField.ignore;
      used.add(f);
      return f;
    }

    return headers.map(guess).toList();
  }

  /// Applies a mapping to the table. Rows without a name are skipped.
  static List<ImportedSoldier> apply(ImportTable table, List<SoldierField> mapping) {
    final result = <ImportedSoldier>[];
    final seenNumbers = <String>{};
    for (final row in table.rows) {
      String get(SoldierField f) {
        final i = mapping.indexOf(f);
        return i < 0 || i >= row.length ? '' : row[i].trim();
      }

      var name = get(SoldierField.fullName);
      if (name.isEmpty) {
        name = '${get(SoldierField.firstName)} ${get(SoldierField.lastName)}'.trim();
      }
      if (name.isEmpty) continue;

      final pn = get(SoldierField.personalNumber).replaceAll(RegExp(r'\D'), '');
      if (pn.isNotEmpty && !seenNumbers.add(pn)) continue; // duplicate in file

      String? orNull(String v) => v.isEmpty ? null : v;
      result.add(ImportedSoldier(
        name: name,
        personalNumber: orNull(pn),
        phone: orNull(get(SoldierField.phone)),
        platoon: orNull(get(SoldierField.platoon)),
      ));
    }
    return result;
  }

  /// Saves to Supabase. Soldiers with a personal number already in the unit are
  /// updated (not duplicated).
  static Future<ImportResult> save(List<ImportedSoldier> soldiers, String unitId) async {
    final client = Supabase.instance.client;
    final withNumber = soldiers.where((s) => s.personalNumber != null).map((s) => s.toRow(unitId)).toList();
    final withoutNumber = soldiers.where((s) => s.personalNumber == null).map((s) => s.toRow(unitId)).toList();

    const chunk = 200;
    try {
      for (var i = 0; i < withNumber.length; i += chunk) {
        final part = withNumber.sublist(i, (i + chunk).clamp(0, withNumber.length));
        await client.from('soldiers').upsert(part, onConflict: 'unit_id,personal_number');
      }
      for (var i = 0; i < withoutNumber.length; i += chunk) {
        final part = withoutNumber.sublist(i, (i + chunk).clamp(0, withoutNumber.length));
        await client.from('soldiers').insert(part);
      }
    } on PostgrestException catch (pe) {
      if (pe.code == 'PGRST204' || pe.message.contains('personal_number')) {
        // Fallback for legacy schema where personal_number column is absent
        final fallbackRows = soldiers.map((s) {
          final pn = s.personalNumber;
          final displayName = (pn != null && pn.isNotEmpty) ? '${s.name} ($pn)' : s.name;
          return <String, dynamic>{
            'name': displayName,
            'unit_id': unitId,
            if (s.phone != null) 'phone_number': s.phone,
            if (s.platoon != null) 'platoon': s.platoon,
          };
        }).toList();

        for (var i = 0; i < fallbackRows.length; i += chunk) {
          final part = fallbackRows.sublist(i, (i + chunk).clamp(0, fallbackRows.length));
          await client.from('soldiers').insert(part);
        }
      } else {
        rethrow;
      }
    }
    return ImportResult(soldiers.length, 0);
  }

  static List<List<String>> _parseCsv(String text) {
    if (text.startsWith('\uFEFF')) text = text.substring(1);
    final firstLine = text.split('\n').first;
    final sep = firstLine.split(';').length > firstLine.split(',').length ? ';' : ',';
    final rows = <List<String>>[];
    var row = <String>[];
    final cell = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            cell.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          cell.write(ch);
        }
      } else if (ch == '"' && cell.isEmpty) {
        inQuotes = true;
      } else if (ch == sep) {
        row.add(cell.toString().trim());
        cell.clear();
      } else if (ch == '\n' || ch == '\r') {
        if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
        row.add(cell.toString().trim());
        cell.clear();
        if (row.any((c) => c.isNotEmpty)) {
          rows.add(row);
        }
        row = <String>[];
      } else {
        cell.write(ch);
      }
    }
    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString().trim());
      if (row.any((c) => c.isNotEmpty)) {
        rows.add(row);
      }
    }
    return rows;
  }
}

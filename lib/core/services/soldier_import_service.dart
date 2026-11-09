import 'dart:convert';
import 'dart:typed_data';

import 'package:chopel_app/core/services/xlsx_reader.dart';
import 'package:chopel_app/core/utils/platoon_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fields a spreadsheet column can be mapped to.
enum SoldierField { ignore, fullName, firstName, lastName, personalNumber, phone, platoon, allergies }

extension SoldierFieldLabel on SoldierField {
  String get label => switch (this) {
        SoldierField.ignore => 'התעלם',
        SoldierField.fullName => 'שם מלא',
        SoldierField.firstName => 'שם פרטי',
        SoldierField.lastName => 'שם משפחה',
        SoldierField.personalNumber => 'מספר אישי',
        SoldierField.phone => 'טלפון',
        SoldierField.platoon => 'מחלקה',
        SoldierField.allergies => 'אלרגיות / רגישויות',
      };
}

/// Raw table read from a file: header row + data rows (all strings).
class ImportTable {
  final List<String> headers;
  final List<List<String>> rows;
  final List<List<String>> allRows;
  final bool firstRowIsHeader;

  ImportTable(
    this.headers,
    this.rows, {
    List<List<String>>? allRows,
    this.firstRowIsHeader = true,
  }) : allRows = allRows ?? [headers, ...rows];

  ImportTable withHeaderMode(bool hasHeader) {
    if (allRows.isEmpty) return this;
    if (hasHeader) {
      return ImportTable(
        allRows.first,
        allRows.skip(1).toList(),
        allRows: allRows,
        firstRowIsHeader: true,
      );
    }
    final generatedHeaders = List<String>.generate(
      allRows.first.length,
      (i) => 'עמודה ${i + 1}',
    );
    return ImportTable(
      generatedHeaders,
      allRows,
      allRows: allRows,
      firstRowIsHeader: false,
    );
  }
}

/// A parsed soldier ready to be saved.
class ImportedSoldier {
  final String name;
  final String? personalNumber;
  final String? phone;
  final String? platoon;
  final String? allergies;

  ImportedSoldier({
    required this.name,
    this.personalNumber,
    this.phone,
    this.platoon,
    this.allergies,
  });

  Map<String, dynamic> toRow(String unitId) => {
        'name': name,
        'personal_number': personalNumber,
        'phone_number': phone,
        'platoon': platoon,
        if (allergies != null) 'allergies': allergies,
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
  /// Reads .xlsx / .xls (HTML/TSV) / .csv bytes into a table. Throws [FormatException] on bad input.
  static ImportTable parse(Uint8List bytes, String fileName) {
    if (bytes.isEmpty) {
      throw const FormatException('הקובץ שנבחר ריק');
    }

    final lower = fileName.toLowerCase();

    // 1. Detect .xlsx by ZIP magic header (PK\x03\x04) even if Android stripped the file extension!
    final isZipXlsx = bytes.length >= 4 &&
        bytes[0] == 0x50 &&
        bytes[1] == 0x4B &&
        bytes[2] == 0x03 &&
        bytes[3] == 0x04;

    // 2. Detect legacy binary BIFF8 .xls (OLE2 compound file: D0 CF 11 E0)
    final isBinaryOleXls = bytes.length >= 4 &&
        bytes[0] == 0xD0 &&
        bytes[1] == 0xCF &&
        bytes[2] == 0x11 &&
        bytes[3] == 0xE0;

    final List<List<String>> all;
    if (isZipXlsx || lower.endsWith('.xlsx')) {
      all = XlsxReader.readFirstSheet(bytes);
    } else if (isBinaryOleXls) {
      throw const FormatException(
        'זהו קובץ אקסל ישן בפורמט בינארי (Excel 97-2003). פתח אותו באקסל/שיטס ושמור כקובץ ‎.xlsx או ‎.csv.',
      );
    } else {
      // Decode text (UTF-8 or UTF-16LE/BE exported by military/HR systems as .xls / .csv / .tsv)
      final text = _decodeTextBytes(bytes);
      final trimmed = text.trimLeft().toLowerCase();
      if (trimmed.startsWith('<html') ||
          trimmed.startsWith('<!doctype') ||
          trimmed.startsWith('<table') ||
          trimmed.contains('<tr')) {
        all = _parseHtmlTable(text);
      } else if (lower.endsWith('.csv') ||
          lower.endsWith('.tsv') ||
          lower.endsWith('.txt') ||
          lower.endsWith('.xls') ||
          text.contains(',') ||
          text.contains('\t') ||
          text.contains(';')) {
        all = _parseCsv(text);
      } else {
        throw const FormatException('יש לבחור קובץ אקסל (‎.xlsx) או ‎.csv תקין');
      }
    }

    final nonEmpty = all.where((r) => r.any((c) => c.trim().isNotEmpty)).toList();
    if (nonEmpty.isEmpty) throw const FormatException('לא נמצאו נתונים בקובץ');

    final width = nonEmpty.map((r) => r.length).reduce((a, b) => a > b ? a : b);
    List<String> pad(List<String> r) => [...r, ...List.filled(width - r.length, '')];

    final paddedAll = nonEmpty.map((r) => pad(r).map((c) => c.trim()).toList()).toList();
    final hasHeader = looksLikeHeaderRow(paddedAll.first, totalRows: paddedAll.length);
    return ImportTable(
      paddedAll.first,
      paddedAll.skip(1).toList(),
      allRows: paddedAll,
      firstRowIsHeader: true,
    ).withHeaderMode(hasHeader);
  }

  /// Parses text copied directly from Excel Mobile, Google Sheets, WhatsApp, or Notes.
  static ImportTable parsePastedText(String rawText) {
    final cleaned = rawText.trim();
    if (cleaned.isEmpty) {
      throw const FormatException('לא הודבקו נתונים. סמן את הטבלה באקסל/שיטס, לחץ "העתק" והדבק כאן.');
    }
    return parse(Uint8List.fromList(utf8.encode(cleaned)), 'pasted.tsv');
  }

  /// Heuristic: returns true when [firstRow] looks like column titles rather than a soldier record.
  static bool looksLikeHeaderRow(List<String> firstRow, {required int totalRows}) {
    if (totalRows <= 1) return false;
    final headerGuess = guessMapping(firstRow);
    final matchedHeaders = headerGuess.where((f) => f != SoldierField.ignore).length;
    final hasPhoneValue = firstRow.any((c) {
      final digits = c.replaceAll(RegExp(r'[\s\-()]'), '');
      return RegExp(r'^(\+?972|0)5\d{8}$').hasMatch(digits);
    });
    final hasPersonalNumberValue = firstRow.any((c) {
      final digits = c.trim();
      return RegExp(r'^\d{5,9}$').hasMatch(digits);
    });
    if (hasPhoneValue || hasPersonalNumberValue) return false;
    return matchedHeaders > 0;
  }

  static String _decodeTextBytes(Uint8List bytes) {
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      // UTF-16LE BOM
      final units = <int>[];
      for (var i = 2; i + 1 < bytes.length; i += 2) {
        units.add(bytes[i] | (bytes[i + 1] << 8));
      }
      return String.fromCharCodes(units);
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  static List<List<String>> _parseHtmlTable(String html) {
    final rows = <List<String>>[];
    final trMatches = RegExp(r'<tr[^>]*>(.*?)</tr>', caseSensitive: false, dotAll: true).allMatches(html);
    for (final tr in trMatches) {
      final rowHtml = tr.group(1) ?? '';
      final cellMatches =
          RegExp(r'<t[dh][^>]*>(.*?)</t[dh]>', caseSensitive: false, dotAll: true).allMatches(rowHtml);
      final cells = cellMatches.map((m) {
        final raw = m.group(1) ?? '';
        return raw
            .replaceAll(RegExp(r'<[^>]+>'), ' ')
            .replaceAll('&nbsp;', ' ')
            .replaceAll('&quot;', '"')
            .replaceAll('&amp;', '&')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
      }).toList();
      if (cells.any((c) => c.isNotEmpty)) {
        rows.add(cells);
      }
    }
    return rows;
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
      } else if (s.contains('אלרגי') || s.contains('רגישו') || s.contains('allerg') || s.contains('g6pd')) {
        f = SoldierField.allergies;
      } else if (s.contains('פרטי') || s.contains('first')) {
        f = SoldierField.firstName;
      } else if (s.contains('משפחה') || s.contains('last')) {
        f = SoldierField.lastName;
      } else if (s.contains('שם') || s.contains('name') || s == 'חייל' || s == 'לוחם') {
        f = SoldierField.fullName;
      }
      if (f == null || used.contains(f)) return SoldierField.ignore;
      used.add(f);
      return f;
    }

    return headers.map(guess).toList();
  }

  /// Combines header-based guessing with sample-value inspection (ideal for headerless pasted tables).
  static List<SoldierField> smartGuessMapping(ImportTable table) {
    final width = table.headers.length;
    final base = table.firstRowIsHeader
        ? List<SoldierField>.from(guessMapping(table.headers))
        : List<SoldierField>.filled(width, SoldierField.ignore);

    final used = base.where((f) => f != SoldierField.ignore).toSet();
    final sampleRows = table.rows.take(10).toList();
    if (sampleRows.isEmpty) return base;

    for (var col = 0; col < width; col++) {
      if (base[col] != SoldierField.ignore) continue;
      final values = sampleRows
          .map((r) => col < r.length ? r[col].trim() : '')
          .where((v) => v.isNotEmpty)
          .toList();
      if (values.isEmpty) continue;

      final phoneHits = values.where((v) {
        final d = v.replaceAll(RegExp(r'[\s\-()]'), '');
        return RegExp(r'^(\+?972|0)5\d{8}$').hasMatch(d);
      }).length;
      if (phoneHits * 2 >= values.length && !used.contains(SoldierField.phone)) {
        base[col] = SoldierField.phone;
        used.add(SoldierField.phone);
        continue;
      }

      final pnHits = values.where((v) => RegExp(r'^\d{5,9}$').hasMatch(v)).length;
      if (pnHits * 2 >= values.length && !used.contains(SoldierField.personalNumber)) {
        base[col] = SoldierField.personalNumber;
        used.add(SoldierField.personalNumber);
        continue;
      }

      final nameHits = values.where((v) {
        return RegExp(r'[\u0590-\u05FFa-zA-Z]').hasMatch(v) &&
            !RegExp(r'^\d+$').hasMatch(v) &&
            (width == 1 || v.contains(' ') || v.length >= 4);
      }).length;
      if (nameHits * 2 >= values.length &&
          !used.contains(SoldierField.fullName) &&
          !used.contains(SoldierField.firstName)) {
        base[col] = SoldierField.fullName;
        used.add(SoldierField.fullName);
        continue;
      }

      final platoonHits = values.where((v) => v.length <= 8).length;
      if (platoonHits == values.length && !used.contains(SoldierField.platoon)) {
        base[col] = SoldierField.platoon;
        used.add(SoldierField.platoon);
      }
    }

    return base;
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
        platoon: orNull(PlatoonHelper.normalize(get(SoldierField.platoon))),
        allergies: orNull(get(SoldierField.allergies)),
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
      if (pe.code == 'PGRST204' ||
          pe.code == '42703' ||
          pe.message.contains('personal_number') ||
          pe.message.contains('allergies')) {
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
    final tabCount = firstLine.split('\t').length;
    final semiCount = firstLine.split(';').length;
    final commaCount = firstLine.split(',').length;
    final pipeCount = firstLine.split('|').length;
    final String sep;
    if (tabCount > 1 && tabCount >= semiCount && tabCount >= commaCount) {
      sep = '\t';
    } else if (semiCount > 1 && semiCount >= commaCount) {
      sep = ';';
    } else if (commaCount > 1) {
      sep = ',';
    } else if (pipeCount > 1) {
      sep = '|';
    } else {
      sep = '\t';
    }
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

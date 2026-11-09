import 'dart:convert';
import 'dart:typed_data';

import 'package:chopel_app/core/services/xlsx_reader.dart';
import 'package:chopel_app/core/utils/platoon_helper.dart';
import 'package:chopel_app/models/soldier.dart';
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

class SoldierMatch {
  final ImportedSoldier imported;
  final Soldier existing;
  const SoldierMatch({required this.imported, required this.existing});
}

class SoldierReconciliation {
  final List<ImportedSoldier> newSoldiers;
  final List<SoldierMatch> toUpdate;
  final List<Soldier> existingNotInImport;

  const SoldierReconciliation({
    required this.newSoldiers,
    required this.toUpdate,
    required this.existingNotInImport,
  });
}

class ImportResult {
  final int total;
  final int updated;
  final int inserted;
  final List<String> insertedNames;
  final List<String> updatedNames;

  const ImportResult({
    required this.total,
    required this.updated,
    required this.inserted,
    this.insertedNames = const [],
    this.updatedNames = const [],
  });

  int get saved => total;
  int get skipped => 0;
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
    var cleaned = rawText.trim();
    if (cleaned.isEmpty) {
      throw const FormatException('לא הודבקו נתונים. סמן את הטבלה באקסל/שיטס, לחץ "העתק" והדבק כאן.');
    }

    // If pasted text does not already contain tab, comma, or semicolon separators,
    // detect space/dash separated lines like "כהן יוסי 8123456" or "8123456 - כהן יוסי"
    if (!cleaned.contains('\t') && !cleaned.contains(',') && !cleaned.contains(';')) {
      final lines = cleaned.split('\n');
      final pnEndPattern = RegExp(r'^(.+?)\s+[\-_–—:,]?\s*(\d{5,9})\s*$');
      final pnStartPattern = RegExp(r'^\s*(\d{5,9})\s+[\-_–—:,]?\s*(.+)$');

      int endMatches = 0;
      int startMatches = 0;
      int nonEmptyLines = 0;

      for (final line in lines) {
        final t = line.trim();
        if (t.isEmpty) continue;
        nonEmptyLines++;
        if (pnEndPattern.hasMatch(t)) endMatches++;
        if (pnStartPattern.hasMatch(t)) startMatches++;
      }

      if (nonEmptyLines > 0 && (endMatches * 2 >= nonEmptyLines || startMatches * 2 >= nonEmptyLines)) {
        final convertedLines = <String>[];
        for (final line in lines) {
          final t = line.trim();
          if (t.isEmpty) continue;
          final mEnd = pnEndPattern.firstMatch(t);
          if (mEnd != null) {
            convertedLines.add('${mEnd.group(1)!.trim()}\t${mEnd.group(2)!.trim()}');
            continue;
          }
          final mStart = pnStartPattern.firstMatch(t);
          if (mStart != null) {
            convertedLines.add('${mStart.group(2)!.trim()}\t${mStart.group(1)!.trim()}');
            continue;
          }
          convertedLines.add(t);
        }
        cleaned = convertedLines.join('\n');
      }
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

      var pn = get(SoldierField.personalNumber).replaceAll(RegExp(r'\D'), '');

      // Fallback: If personalNumber is empty, check if name has 5-9 digits:
      if (pn.isEmpty) {
        final pnMatch = RegExp(r'\b(\d{5,9})\b').firstMatch(name);
        if (pnMatch != null) {
          pn = pnMatch.group(1)!;
          name = name.replaceFirst(pnMatch.group(0)!, '');
          name = name.replaceAll(RegExp(r'[\-_–—:(),]'), ' ');
          name = name.replaceAll(RegExp(r'(^|\s+)(מ\.?א|מ"?א|מא|מספר\s+אישי)($|\s+)'), ' ');
          name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
        }
      }

      // Remove leading numbering like "1. ", "02) ", "1 - "
      name = name.replaceFirst(RegExp(r'^\s*\d+[\.\)\-\:\s]+\s*'), '').trim();
      if (name.isEmpty) continue;

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

  static String cleanName(String raw) {
    var s = raw;
    // Strip directional and invisible unicode marks (LRM \u200E, RLM \u200F, ZWSP \u200B, NBSP \u00A0, BOM \uFEFF)
    s = s.replaceAll(RegExp(r'[\u200E\u200F\u200B\u200C\u200D\u202A-\u202E\uFEFF\u00A0]'), ' ');
    // Remove parenthesized notes like (מחלקה 1), (חובש), (אני)
    s = s.replaceAll(RegExp(r'\(.*?\)'), ' ');
    // Remove leading numbering like "1. ", "01. ", "1) ", "1 - "
    s = s.replaceFirst(RegExp(r'^\s*\d+[\.\)\-\:\s]+\s*'), ' ');
    // Remove military ranks if at start of name
    s = s.replaceFirst(
      RegExp(r'^\s*(טוראי|רב"?ט|סמל|סמ"?ר|סמר|רס"?ל|רסל|רס"?ר|רסר|רס"?ם|רסם|רס"?פ|רספ|סג"?ם|סגם|סגן|סרן|רס"?ן|רסן|לוחם|חייל)\s+'),
      ' ',
    );
    // Remove punctuation, dashes, quotes, slashes
    s = s.replaceAll(RegExp(r'[\-_/\\.,:;"\x27״׳!?]'), ' ');
    // Remove standalone digits
    s = s.replaceAll(RegExp(r'\b\d+\b'), ' ');
    // Lowercase (for any English letters) and normalize whitespace
    s = s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// Compares two Hebrew names intelligently:
  /// - Exact match after cleaning
  /// - Inverted word match ("כהן יוסי" == "יוסי כהן")
  /// - Set equality of words ({"אביאל", "שבתאי"} == {"שבתאי", "אביאל"})
  /// - Multi-word subset match (e.g. "אביאל יוסף שבתאי" vs "אביאל שבתאי")
  static bool namesMatch(String rawA, String rawB) {
    final a = cleanName(rawA);
    final b = cleanName(rawB);
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;

    final wordsA = a.split(' ').where((w) => w.isNotEmpty).toList();
    final wordsB = b.split(' ').where((w) => w.isNotEmpty).toList();
    if (wordsA.isEmpty || wordsB.isEmpty) return false;

    // Word set match (handles any permutation, e.g. "כהן יוסי" == "יוסי כהן")
    final setA = wordsA.toSet();
    final setB = wordsB.toSet();
    if (setA.length == setB.length && setA.containsAll(setB)) {
      return true;
    }

    // Two words inverted
    if (wordsA.length == 2 && wordsB.length == 2) {
      if (wordsA[0] == wordsB[1] && wordsA[1] == wordsB[0]) return true;
    }

    // 2 words vs 3 words (e.g. middle name present in one version)
    if ((wordsA.length == 2 && wordsB.length == 3) || (wordsA.length == 3 && wordsB.length == 2)) {
      final shorter = wordsA.length < wordsB.length ? setA : setB;
      final longer = wordsA.length < wordsB.length ? setB : setA;
      if (longer.containsAll(shorter)) return true;
    }

    return false;
  }

  static String cleanPn(String? raw) {
    if (raw == null) return '';
    return raw.replaceAll(RegExp(r'\D'), '');
  }

  static String cleanPhone(String? raw) {
    if (raw == null) return '';
    var d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('972')) d = '0${d.substring(3)}';
    return d;
  }

  /// Compares imported soldiers against existing soldiers in the unit.
  /// Identifies soldiers to update (by P.N. or Name or Phone) and genuinely new soldiers to add.
  static SoldierReconciliation reconcile({
    required List<ImportedSoldier> imported,
    required List<Soldier> existingInDb,
  }) {
    final List<SoldierMatch> toUpdate = [];
    final List<ImportedSoldier> newSoldiers = [];
    final Set<String> matchedExistingIds = {};

    for (final imp in imported) {
      final impPn = cleanPn(imp.personalNumber);
      final impPhone = cleanPhone(imp.phone);

      Soldier? match;

      // 1. Try matching by Personal Number (if both have personal number)
      if (impPn.isNotEmpty) {
        for (final e in existingInDb) {
          if (!matchedExistingIds.contains(e.id) && cleanPn(e.personalNumber) == impPn) {
            match = e;
            break;
          }
        }
      }

      // 2. Try matching by Name (handles inverted order, rank, numbering, unicode)
      if (match == null) {
        for (final e in existingInDb) {
          if (!matchedExistingIds.contains(e.id) && namesMatch(imp.name, e.name)) {
            match = e;
            break;
          }
        }
      }

      // 3. Try matching by Phone number (if valid Israeli phone)
      if (match == null && impPhone.length >= 9) {
        for (final e in existingInDb) {
          if (!matchedExistingIds.contains(e.id) && cleanPhone(e.phoneNumber) == impPhone) {
            match = e;
            break;
          }
        }
      }

      if (match != null) {
        matchedExistingIds.add(match.id);
        toUpdate.add(SoldierMatch(imported: imp, existing: match));
      } else {
        newSoldiers.add(imp);
      }
    }

    final existingNotInImport = existingInDb
        .where((e) => !matchedExistingIds.contains(e.id))
        .toList();

    return SoldierReconciliation(
      newSoldiers: newSoldiers,
      toUpdate: toUpdate,
      existingNotInImport: existingNotInImport,
    );
  }

  /// Saves imported soldiers to Supabase using smart matching.
  /// Existing soldiers (matched by P.N., name, or phone) are UPDATED by ID.
  /// Genuinely new soldiers are INSERTED. No duplicates are created.
  static Future<ImportResult> save(List<ImportedSoldier> soldiers, String unitId) async {
    final client = Supabase.instance.client;

    List<Map<String, dynamic>> existingRows = [];
    try {
      final res = await client.from('soldiers').select().eq('unit_id', unitId);
      existingRows = List<Map<String, dynamic>>.from(res as List);
    } catch (_) {}

    final existingSoldiers = existingRows.map((r) => Soldier.fromMap(r)).toList();
    final recon = reconcile(imported: soldiers, existingInDb: existingSoldiers);

    int updatedCount = 0;
    int insertedCount = 0;
    final List<String> updatedNames = [];
    final List<String> insertedNames = [];

    // 1. Update existing soldiers by their ID
    for (final match in recon.toUpdate) {
      final imp = match.imported;
      final exist = match.existing;

      final updatePayload = <String, dynamic>{
        'name': imp.name,
        if (imp.personalNumber != null && imp.personalNumber!.isNotEmpty)
          'personal_number': imp.personalNumber,
        if (imp.phone != null && imp.phone!.isNotEmpty)
          'phone_number': imp.phone,
        if (imp.platoon != null && imp.platoon!.isNotEmpty)
          'platoon': PlatoonHelper.normalize(imp.platoon),
        if (imp.allergies != null && imp.allergies!.isNotEmpty)
          'allergies': imp.allergies,
      };

      try {
        await client.from('soldiers').update(updatePayload).eq('id', exist.id);
        updatedCount++;
        updatedNames.add(imp.name);
      } catch (e) {
        try {
          final fallbackPayload = <String, dynamic>{
            'name': (imp.personalNumber != null && imp.personalNumber!.isNotEmpty)
                ? '${imp.name} (${imp.personalNumber})'
                : imp.name,
            if (imp.phone != null) 'phone_number': imp.phone,
            if (imp.platoon != null) 'platoon': PlatoonHelper.normalize(imp.platoon),
          };
          await client.from('soldiers').update(fallbackPayload).eq('id', exist.id);
          updatedCount++;
          updatedNames.add(imp.name);
        } catch (_) {}
      }
    }

    // 2. Insert new soldiers
    const chunk = 100;
    final newRows = recon.newSoldiers.map((s) => s.toRow(unitId)).toList();
    for (var i = 0; i < newRows.length; i += chunk) {
      final part = newRows.sublist(i, (i + chunk).clamp(0, newRows.length));
      try {
        await client.from('soldiers').insert(part);
        insertedCount += part.length;
        insertedNames.addAll(recon.newSoldiers.skip(i).take(part.length).map((s) => s.name));
      } catch (e) {
        try {
          final fallbackPart = recon.newSoldiers.skip(i).take(part.length).map((s) {
            final pn = s.personalNumber;
            final displayName = (pn != null && pn.isNotEmpty) ? '${s.name} ($pn)' : s.name;
            return <String, dynamic>{
              'name': displayName,
              'unit_id': unitId,
              if (s.phone != null) 'phone_number': s.phone,
              if (s.platoon != null) 'platoon': PlatoonHelper.normalize(s.platoon),
            };
          }).toList();
          await client.from('soldiers').insert(fallbackPart);
          insertedCount += fallbackPart.length;
          insertedNames.addAll(recon.newSoldiers.skip(i).take(part.length).map((s) => s.name));
        } catch (_) {}
      }
    }

    return ImportResult(
      total: updatedCount + insertedCount,
      updated: updatedCount,
      inserted: insertedCount,
      updatedNames: updatedNames,
      insertedNames: insertedNames,
    );
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

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Minimal .xlsx reader: returns the first worksheet as rows of strings.
/// (The `excel` package conflicts with syncfusion, so we read the XML directly.)
class XlsxReader {
  static List<List<String>> readFirstSheet(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);

    String? readEntry(String name) {
      final f = archive.findFile(name);
      if (f == null) return null;
      return utf8.decode(f.content as List<int>, allowMalformed: true);
    }

    // Shared strings table
    final shared = <String>[];
    final ssXml = readEntry('xl/sharedStrings.xml');
    if (ssXml != null) {
      for (final si in XmlDocument.parse(ssXml).findAllElements('si')) {
        shared.add(si.findAllElements('t').map((t) => t.innerText).join());
      }
    }

    // First sheet path (via workbook rels when available)
    String sheetPath = 'xl/worksheets/sheet1.xml';
    final wb = readEntry('xl/workbook.xml');
    final rels = readEntry('xl/_rels/workbook.xml.rels');
    if (wb != null && rels != null) {
      final firstSheet = XmlDocument.parse(wb).findAllElements('sheet').firstOrNull;
      final rid = firstSheet?.attributes
          .firstWhere((a) => a.name.local == 'id', orElse: () => XmlAttribute(XmlName('x'), ''))
          .value;
      if (rid != null && rid.isNotEmpty) {
        final rel = XmlDocument.parse(rels)
            .findAllElements('Relationship')
            .where((r) => r.getAttribute('Id') == rid)
            .firstOrNull;
        final target = rel?.getAttribute('Target');
        if (target != null) {
          sheetPath = target.startsWith('/') ? target.substring(1) : 'xl/$target';
        }
      }
    }

    final sheetXml = readEntry(sheetPath) ?? readEntry('xl/worksheets/sheet1.xml');
    if (sheetXml == null) throw const FormatException('לא נמצא גיליון בקובץ');

    final rows = <List<String>>[];
    for (final row in XmlDocument.parse(sheetXml).findAllElements('row')) {
      final cells = <int, String>{};
      var nextCol = 0;
      for (final c in row.findElements('c')) {
        final ref = c.getAttribute('r');
        final col = ref != null ? _colIndex(ref) : nextCol;
        nextCol = col + 1;
        final type = c.getAttribute('t');
        String value;
        if (type == 'inlineStr') {
          value = c.findAllElements('t').map((t) => t.innerText).join();
        } else {
          final v = c.findElements('v').firstOrNull?.innerText ?? '';
          if (type == 's') {
            final i = int.tryParse(v);
            value = (i != null && i < shared.length) ? shared[i] : '';
          } else if (type == null || type == 'n') {
            final d = double.tryParse(v);
            value = (d != null && d == d.roundToDouble() && d.abs() < 1e15) ? d.toInt().toString() : v;
          } else {
            value = v;
          }
        }
        cells[col] = value;
      }
      if (cells.isEmpty) {
        rows.add([]);
        continue;
      }
      final maxCol = cells.keys.reduce((a, b) => a > b ? a : b);
      rows.add(List.generate(maxCol + 1, (i) => cells[i] ?? ''));
    }
    return rows;
  }

  static int _colIndex(String ref) {
    var n = 0;
    for (final ch in ref.codeUnits) {
      if (ch < 65 || ch > 90) break; // stop at digits
      n = n * 26 + (ch - 64);
    }
    return n - 1;
  }
}

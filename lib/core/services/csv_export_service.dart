import 'dart:convert';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:chopel_app/core/utils/platoon_helper.dart';
import 'package:chopel_app/models/medical_case.dart';
import 'package:chopel_app/models/soldier.dart';

class CsvExportService {
  static const String utf8Bom = '\uFEFF';

  static String escapeCsvField(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final cleaned = raw.replaceAll('\r\n', ' ').replaceAll('\n', ' ').trim();
    if (cleaned.contains(',') || cleaned.contains('"') || cleaned.contains(';')) {
      return '"${cleaned.replaceAll('"', '""')}"';
    }
    return cleaned;
  }

  /// Generates a UTF-8 with BOM CSV string for all soldiers in the company.
  static String generateSoldiersCsv(List<Soldier> soldiers) {
    final sorted = List<Soldier>.from(soldiers)..sort((a, b) => a.name.compareTo(b.name));
    final sb = StringBuffer(utf8Bom);
    sb.writeln('שם מלא,מספר אישי,מחלקה,טלפון,רגישויות ואלרגיות');

    for (final s in sorted) {
      final row = [
        escapeCsvField(s.name),
        escapeCsvField(s.personalNumber),
        escapeCsvField(PlatoonHelper.formatDisplay(s.platoon)),
        escapeCsvField(s.phoneNumber),
        escapeCsvField(s.allergies),
      ].join(',');
      sb.writeln(row);
    }

    return sb.toString();
  }

  /// Generates a UTF-8 with BOM CSV string for medical cases.
  static String generateMedicalCasesCsv(List<MedicalCase> cases, List<Soldier> soldiers) {
    final soldierMap = {for (final s in soldiers) s.id: s};
    final sorted = List<MedicalCase>.from(cases)
      ..sort((a, b) => b.createdDate.compareTo(a.createdDate));

    final sb = StringBuffer(utf8Bom);
    sb.writeln('תאריך פתיחה,שם החייל,מספר אישי,מחלקה,קטגוריה,דחיפות,סטטוס,תיאור וטיפול,רגישויות');

    for (final c in sorted) {
      final s = soldierMap[c.soldierId];
      final dateStr = c.createdDate.length >= 16 ? c.createdDate.substring(0, 16).replaceFirst('T', ' ') : c.createdDate;
      final statusHeb = c.status == 'COMPLETED' ? 'הושלם' : 'בטיפול / מעקב';

      final row = [
        escapeCsvField(dateStr),
        escapeCsvField(s?.name ?? 'חייל לא ידוע'),
        escapeCsvField(s?.personalNumber),
        escapeCsvField(PlatoonHelper.formatDisplay(s?.platoon)),
        escapeCsvField(c.category ?? 'שגרת מרפאה'),
        escapeCsvField(c.severity ?? 'שגרה'),
        escapeCsvField(statusHeb),
        escapeCsvField(c.description),
        escapeCsvField(s?.allergies),
      ].join(',');
      sb.writeln(row);
    }

    return sb.toString();
  }

  static Future<void> shareCsv({
    required String csvContent,
    required String fileName,
    required String title,
  }) async {
    try {
      final bytes = Uint8List.fromList(utf8.encode(csvContent));
      final xFile = XFile.fromData(
        bytes,
        mimeType: 'text/csv',
        name: fileName,
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          subject: title,
          text: title,
        ),
      );
    } catch (_) {
      await SharePlus.instance.share(
        ShareParams(
          subject: title,
          text: csvContent,
        ),
      );
    }
  }
}


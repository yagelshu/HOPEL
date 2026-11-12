import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/models/medical_case.dart';
import 'package:chopel_app/models/soldier.dart';

class P2pSyncResult {
  final bool success;
  final int casesMerged;
  final int casesSkipped;
  final String sourceMedic;
  final DateTime? exportedAt;
  final String? errorMessage;

  const P2pSyncResult({
    required this.success,
    this.casesMerged = 0,
    this.casesSkipped = 0,
    this.sourceMedic = 'לא ידוע',
    this.exportedAt,
    this.errorMessage,
  });
}

class P2pSyncService {
  static const String packageHeader = 'HOPEL_P2P_V1';

  /// Generates a portable export payload containing local medical cases and metadata.
  static Future<String> generateExportPayload({
    required List<MedicalCase> cases,
    required List<Soldier> soldiers,
  }) async {
    final user = AuthService().currentUser;

    final packet = {
      'header': packageHeader,
      'exported_at': DateTime.now().toIso8601String(),
      'unit_id': user?.unitId ?? '',
      'source_medic': AuthService().effectiveUserName,
      'cases': cases.map((c) => c.toMap()).toList(),
      'soldiers_count': soldiers.length,
    };

    final rawJson = jsonEncode(packet);
    // Encode to base64 so it can be cleanly shared as text or file without encoding glitches
    final base64Payload = base64Encode(utf8.encode(rawJson));
    return '$packageHeader:$base64Payload';
  }

  /// Parses and merges an imported P2P payload into the local storage.
  static Future<P2pSyncResult> importAndMerge(String payload) async {
    try {
      final trimmed = payload.trim();
      String base64Content = trimmed;

      if (trimmed.startsWith('$packageHeader:')) {
        base64Content = trimmed.substring('$packageHeader:'.length);
      }

      final jsonStr = utf8.decode(base64Decode(base64Content));
      final Map<String, dynamic> data = jsonDecode(jsonStr);

      if (data['header'] != packageHeader) {
        return const P2pSyncResult(
          success: false,
          errorMessage: 'קובץ או קוד לא תואם למבנה סנכרון חופ"ל (P2P).',
        );
      }

      final sourceMedic = data['source_medic']?.toString() ?? 'חובש עמית';
      final exportedAt = DateTime.tryParse(data['exported_at']?.toString() ?? '');
      final rawCases = data['cases'] as List<dynamic>? ?? [];

      final importedCases = rawCases.map((m) => MedicalCase.fromMap(m as Map<String, dynamic>)).toList();

      // Merge into local cache
      final user = AuthService().currentUser;
      final cacheKey = user?.activeDeploymentId != null ? 'cached_cases_${user!.activeDeploymentId}' : 'cached_cases_offline';

      final prefs = await SharedPreferences.getInstance();
      final localCasesStr = prefs.getString(cacheKey);

      final Map<String, MedicalCase> mergedMap = {};

      if (localCasesStr != null && localCasesStr.isNotEmpty) {
        try {
          final List<dynamic> localDecoded = jsonDecode(localCasesStr);
          for (final m in localDecoded) {
            final c = MedicalCase.fromMap(m as Map<String, dynamic>);
            mergedMap[c.id] = c;
          }
        } catch (_) {}
      }

      int mergedCount = 0;
      int skippedCount = 0;

      for (final inc in importedCases) {
        if (!mergedMap.containsKey(inc.id)) {
          mergedMap[inc.id] = inc;
          mergedCount++;
        } else {
          // Conflict resolution: pick the one with newer updated_date
          final existing = mergedMap[inc.id]!;
          final existingDate = DateTime.tryParse(existing.updatedDate ?? existing.createdDate);
          final incomingDate = DateTime.tryParse(inc.updatedDate ?? inc.createdDate);

          if (incomingDate != null && (existingDate == null || incomingDate.isAfter(existingDate))) {
            mergedMap[inc.id] = inc;
            mergedCount++;
          } else {
            skippedCount++;
          }
        }
      }

      // Save back to local cache
      final updatedList = mergedMap.values.map((c) => c.toMap()).toList();
      await prefs.setString(cacheKey, jsonEncode(updatedList));

      return P2pSyncResult(
        success: true,
        casesMerged: mergedCount,
        casesSkipped: skippedCount,
        sourceMedic: sourceMedic,
        exportedAt: exportedAt,
      );
    } catch (e) {
      return P2pSyncResult(
        success: false,
        errorMessage: 'שגיאה בפענוח נתוני הסנכרון: $e',
      );
    }
  }
}


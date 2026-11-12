import 'package:intl/intl.dart';
import 'package:chopel_app/models/medical_case.dart';
import 'package:chopel_app/models/soldier.dart';
import 'package:chopel_app/core/utils/platoon_helper.dart';

enum HandoverWindow { last24Hours, last48Hours, last7Days }

class ShiftHandoverService {
  static String generateReport({
    required List<MedicalCase> cases,
    required List<Soldier> soldiers,
    HandoverWindow window = HandoverWindow.last24Hours,
    int? activeMedicsOnStandby,
    int? totalMedicsCount,
    String? customNotes,
    DateTime? nowOverride,
  }) {
    final now = nowOverride ?? DateTime.now();
    final int hours = switch (window) {
      HandoverWindow.last24Hours => 24,
      HandoverWindow.last48Hours => 48,
      HandoverWindow.last7Days => 168,
    };

    final windowTitle = switch (window) {
      HandoverWindow.last24Hours => '24 שעות אחרונות',
      HandoverWindow.last48Hours => '48 שעות אחרונות',
      HandoverWindow.last7Days => '7 ימים אחרונים',
    };

    final cutoff = now.subtract(Duration(hours: hours));
    final soldierMap = {for (final s in soldiers) s.id: s};

    final periodCases = cases.where((c) {
      final dt = DateTime.tryParse(c.createdDate)?.toLocal();
      if (dt == null) return false;
      return dt.isAfter(cutoff);
    }).toList();

    // Cases requiring ongoing attention (even if created slightly earlier if still open)
    final pendingCases = cases.where((c) {
      final isPending = c.status != 'COMPLETED' && c.status != 'טופל';
      if (!isPending) return false;
      final dt = DateTime.tryParse(c.createdDate)?.toLocal();
      return dt != null && dt.isAfter(now.subtract(const Duration(days: 14)));
    }).toList();

    final completedCases = periodCases.where((c) => c.status == 'COMPLETED' || c.status == 'טופל').toList();

    final buffer = StringBuffer();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);

    buffer.writeln('📋 *דוח חפיפת מרפאה פלוגתית - חופ"ל* 🩺');
    buffer.writeln('⏱️ *תקופת דיווח:* $windowTitle ($dateStr)');
    buffer.writeln('-----------------------------------');

    // 1. Operational status
    buffer.writeln('📊 *תמונת מצב כללית:*');
    buffer.writeln('• סה"כ פניות חדשות בתקופה: ${periodCases.length}');
    buffer.writeln('• פניות פעילות הדורשות מעקב: ${pendingCases.length}');
    buffer.writeln('• פניות שהושלמו וטופלו: ${completedCases.length}');
    if (activeMedicsOnStandby != null && totalMedicsCount != null) {
      buffer.writeln('• חובשים בכוננות מוצב: $activeMedicsOnStandby מתוך $totalMedicsCount');
    }
    buffer.writeln('');

    // 2. Active cases needing attention
    if (pendingCases.isNotEmpty) {
      buffer.writeln('🚨 *חיילים במעקב פעיל להמשך משמרת (${pendingCases.length}):*');
      int idx = 1;
      for (final c in pendingCases) {
        final soldier = soldierMap[c.soldierId];
        final name = soldier?.name ?? 'חייל לא מזוהה';
        final platoon = soldier?.platoon != null ? ' (${PlatoonHelper.formatDisplay(soldier!.platoon)})' : '';
        final pn = soldier?.personalNumber != null ? ' [מ.א ${soldier!.personalNumber}]' : '';
        final desc = c.description != null && c.description!.isNotEmpty ? c.description! : (c.category ?? 'ללא פירוט');
        buffer.writeln('$idx. $name$platoon$pn: $desc');
        idx++;
      }
      buffer.writeln('');
    } else {
      buffer.writeln('✅ *אין כרגע חיילים במעקב חריג הדורש התערבות מיידית.*');
      buffer.writeln('');
    }

    // 3. Completed cases highlights
    if (completedCases.isNotEmpty) {
      buffer.writeln('✔️ *פניות שטופלו והושלמו בתקופה (${completedCases.length}):*');
      for (final c in completedCases.take(5)) {
        final soldier = soldierMap[c.soldierId];
        final name = soldier?.name ?? 'חייל';
        final desc = c.category ?? c.description ?? 'טיפול שגרתי';
        buffer.writeln('• $name - $desc');
      }
      if (completedCases.length > 5) {
        buffer.writeln('• ...ועוד ${completedCases.length - 5} פניות שטופלו.');
      }
      buffer.writeln('');
    }

    // 4. Custom notes
    if (customNotes != null && customNotes.trim().isNotEmpty) {
      buffer.writeln('📝 *דגשי חפיפה והנחיות מיוחדות:*');
      buffer.writeln(customNotes.trim());
      buffer.writeln('');
    }

    buffer.writeln('הופק אוטומטית מאפליקציית חופ"ל');
    return buffer.toString();
  }
}


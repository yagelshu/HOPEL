import 'package:chopel_app/models/medical_case.dart';
import 'package:chopel_app/models/soldier.dart';
import 'package:chopel_app/core/utils/platoon_helper.dart';

class OutbreakAlert {
  final String id;
  final String category;
  final String? platoon;
  final int caseCount;
  final int windowHours;
  final List<String> affectedSoldierNames;
  final List<String> caseIds;
  final String recommendation;
  final DateTime latestCaseDate;

  const OutbreakAlert({
    required this.id,
    required this.category,
    this.platoon,
    required this.caseCount,
    required this.windowHours,
    required this.affectedSoldierNames,
    required this.caseIds,
    required this.recommendation,
    required this.latestCaseDate,
  });

  bool get isCompanyWide => platoon == null || platoon!.isEmpty;

  String get title => isCompanyWide
      ? 'התרעת התפרצות פלוגתית: $category ($caseCount מקרים)'
      : 'חריגת תחלואה ב${PlatoonHelper.formatDisplay(platoon)}: $category ($caseCount מקרים)';
}

class OutbreakRadarService {
  static const int defaultWindowHours = 72;
  static const int platoonThreshold = 3;
  static const int companyThreshold = 5;

  /// Analyzes medical cases and soldiers to detect syndromic disease clusters.
  static List<OutbreakAlert> detectOutbreaks({
    required List<MedicalCase> cases,
    required List<Soldier> soldiers,
    int windowHours = defaultWindowHours,
    DateTime? nowOverride,
  }) {
    if (cases.isEmpty) return const [];

    final now = nowOverride ?? DateTime.now();
    final cutoff = now.subtract(Duration(hours: windowHours));

    final soldierMap = {for (final s in soldiers) s.id: s};

    // Filter relevant cases within the time window
    final recentCases = cases.where((c) {
      final dt = DateTime.tryParse(c.createdDate)?.toLocal();
      if (dt == null) return false;
      return dt.isAfter(cutoff);
    }).toList();

    if (recentCases.isEmpty) return const [];

    // Group by category
    final categoryGroups = <String, List<MedicalCase>>{};
    for (final c in recentCases) {
      final cat = (c.category ?? 'שגרת מרפאה').trim();
      // Ignore routine non-infectious / administrative categories
      if (cat.isEmpty || cat == 'אישור רפואי' || cat == 'מנהלה' || cat == 'פטורים') continue;
      categoryGroups.putIfAbsent(cat, () => []).add(c);
    }

    final alerts = <OutbreakAlert>[];

    categoryGroups.forEach((category, catCases) {
      // 1. Check Platoon-level clusters
      final platoonGroups = <String, List<MedicalCase>>{};
      for (final c in catCases) {
        final soldier = soldierMap[c.soldierId];
        final platoon = PlatoonHelper.normalize(soldier?.platoon);
        if (platoon.isNotEmpty) {
          platoonGroups.putIfAbsent(platoon, () => []).add(c);
        }
      }

      platoonGroups.forEach((platoon, platoonCases) {
        if (platoonCases.length >= platoonThreshold) {
          final soldierNames = platoonCases.map((c) {
            final s = soldierMap[c.soldierId];
            return s?.name ?? 'חייל';
          }).toSet().toList();

          final latest = platoonCases
              .map((c) => DateTime.tryParse(c.createdDate)?.toLocal() ?? now)
              .reduce((a, b) => a.isAfter(b) ? a : b);

          alerts.add(OutbreakAlert(
            id: 'platoon_${category}_${platoon}_${latest.millisecondsSinceEpoch}',
            category: category,
            platoon: platoon,
            caseCount: platoonCases.length,
            windowHours: windowHours,
            affectedSoldierNames: soldierNames,
            caseIds: platoonCases.map((c) => c.id).toList(),
            recommendation: _getRecommendation(category, isPlatoon: true, platoon: platoon),
            latestCaseDate: latest,
          ));
        }
      });

      // 2. Check Company-wide clusters (if total >= companyThreshold)
      if (catCases.length >= companyThreshold) {
        final allSoldierNames = catCases.map((c) {
          final s = soldierMap[c.soldierId];
          return s?.name ?? 'חייל';
        }).toSet().toList();

        final latest = catCases
            .map((c) => DateTime.tryParse(c.createdDate)?.toLocal() ?? now)
            .reduce((a, b) => a.isAfter(b) ? a : b);

        alerts.add(OutbreakAlert(
          id: 'company_${category}_${latest.millisecondsSinceEpoch}',
          category: category,
          platoon: null,
          caseCount: catCases.length,
          windowHours: windowHours,
          affectedSoldierNames: allSoldierNames,
          caseIds: catCases.map((c) => c.id).toList(),
          recommendation: _getRecommendation(category, isPlatoon: false),
          latestCaseDate: latest,
        ));
      }
    });

    // Sort by most recent
    alerts.sort((a, b) => b.latestCaseDate.compareTo(a.latestCaseDate));
    return alerts;
  }

  static String _getRecommendation(String category, {required bool isPlatoon, String? platoon}) {
    final target = isPlatoon ? 'ב${PlatoonHelper.formatDisplay(platoon)}' : 'בכלל הפלוגה';

    final lower = category.toLowerCase();
    if (lower.contains('עיכול') || lower.contains('בטן') || lower.contains('שלשול')) {
      return 'חשד להתפרצות גסטרו / הרעלת מזון $target. בצע ביקורת תברואה דחופה במטבח המוצב ובמי השתייה, ודא היגיינת ידיים ובודד לוחמים משלשלים. חובה לעדכן רופא גדוד.';
    }
    if (lower.contains('עור') || lower.contains('פריחה') || lower.contains('זיהום')) {
      return 'עלייה חריגה בנגעי עור $target (שפשפות קשות / לישמניה / פטרת חיילים). מומלץ לוודא אוורור מגורים ומכולות, אספקת משחות וביקורת רופא.';
    }
    if (lower.contains('חום') || lower.contains('נשימה') || lower.contains('גרון')) {
      return 'חשד להדבקה נשימתית / ויראלית $target באוהלים ובמכולות. יש להקפיד על אוורור, מרחקי שינה ומעקב חום קפדני.';
    }
    return 'זוהתה צבירת מקרים חריגה של $category $target ב-$defaultWindowHours השעות האחרונות. מומלץ לבצע תחקור רפואי ולדווח לחוג"ד.';
  }

  /// Builds a WhatsApp message to report the outbreak to the Battalion Doctor / Hogad.
  static String formatReportForDoctor(OutbreakAlert alert) {
    final buffer = StringBuffer();
    buffer.writeln('⚠️ *התרעת מודיעין רפואי פלוגתי (מכ"ם תחלואה)* ⚠️');
    buffer.writeln('-----------------------------------');
    buffer.writeln('📌 *קטגוריה:* ${alert.category}');
    buffer.writeln('📍 *מיקום/מסגרת:* ${alert.isCompanyWide ? "כלל הפלוגה" : PlatoonHelper.formatDisplay(alert.platoon)}');
    buffer.writeln('⏱️ *חלון זמן:* ${alert.windowHours} שעות אחרונות');
    buffer.writeln('👥 *כמות נפגעים:* ${alert.caseCount} לוחמים');
    if (alert.affectedSoldierNames.isNotEmpty) {
      buffer.writeln('📋 *שמות החיילים:* ${alert.affectedSoldierNames.join(", ")}');
    }
    buffer.writeln('');
    buffer.writeln('💡 *המלצות שטח:*');
    buffer.writeln(alert.recommendation);
    buffer.writeln('');
    buffer.writeln('נשלח אוטומטית מאפליקציית חופ"ל');
    return buffer.toString();
  }
}


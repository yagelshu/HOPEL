import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/core/utils/platoon_helper.dart';
import 'package:chopel_app/features/learning/medication_guide_screen.dart';
import 'package:chopel_app/features/medical_cases/medical_case_detail_screen.dart';
import 'package:chopel_app/features/profile/soldier_medical_history_screen.dart';
import 'package:chopel_app/models/equipment.dart';
import 'package:chopel_app/models/medical_case.dart';
import 'package:chopel_app/models/soldier.dart';
import 'package:chopel_app/theme/app_theme.dart';

class CommandSearchSheet {
  static void show(
    BuildContext context, {
    required List<Soldier> soldiers,
    required List<MedicalCase> cases,
    required List<Equipment> equipment,
  }) {
    final searchController = TextEditingController();
    String query = '';

    final soldierMap = {for (final s in soldiers) s.id: s};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setModalState) {
            final q = query.trim().toLowerCase();
            final cleanQ = q.replaceAll(RegExp(r'[\s-]'), '');

            final matchedSoldiers = q.isEmpty
                ? <Soldier>[]
                : soldiers.where((s) {
                    final pn = (s.personalNumber ?? '').replaceAll(RegExp(r'[\s-]'), '').toLowerCase();
                    return s.name.toLowerCase().contains(q) ||
                        (pn.isNotEmpty && pn.contains(cleanQ)) ||
                        (s.phoneNumber != null && s.phoneNumber!.contains(cleanQ)) ||
                        (s.platoon != null && s.platoon!.toLowerCase().contains(q)) ||
                        (s.allergies != null && s.allergies!.toLowerCase().contains(q));
                  }).take(8).toList();

            final matchedCases = q.isEmpty
                ? <MedicalCase>[]
                : cases.where((c) {
                    final sName = soldierMap[c.soldierId]?.name.toLowerCase() ?? '';
                    return (c.description ?? '').toLowerCase().contains(q) ||
                        (c.category ?? '').toLowerCase().contains(q) ||
                        sName.contains(q);
                  }).take(6).toList();

            final matchedMeds = q.isEmpty
                ? <Medication>[]
                : MedicationGuideScreen.medications.where((m) {
                    return m.name.toLowerCase().contains(q) ||
                        m.activeIngredient.toLowerCase().contains(q) ||
                        m.indications.toLowerCase().contains(q) ||
                        m.category.toLowerCase().contains(q);
                  }).take(6).toList();

            final matchedEquipment = q.isEmpty
                ? <Equipment>[]
                : equipment.where((eq) {
                    return eq.name.toLowerCase().contains(q) || eq.category.toLowerCase().contains(q);
                  }).take(6).toList();

            final hasAnyResults = matchedSoldiers.isNotEmpty ||
                matchedCases.isNotEmpty ||
                matchedMeds.isNotEmpty ||
                matchedEquipment.isNotEmpty;

            return Container(
              height: MediaQuery.of(sheetCtx).size.height * 0.82,
              padding: EdgeInsets.only(
                top: AppTheme.spacing16,
                left: AppTheme.spacing16,
                right: AppTheme.spacing16,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + AppTheme.spacing16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.search, color: AppTheme.primaryGreen, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'חיפוש-על גלובלי (חיילים • פניות • תרופות • ציוד)',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.x, color: AppTheme.textSecondary),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    style: TextStyle(color: AppTheme.textPrimary),
                    onChanged: (val) => setModalState(() => query = val),
                    decoration: InputDecoration(
                      hintText: 'הקלד שם חייל, מ.א, תלונה, שם תרופה או פריט ציוד...',
                      prefixIcon: Icon(LucideIcons.search, color: AppTheme.textSecondary),
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: Icon(LucideIcons.x, size: 16, color: AppTheme.textSecondary),
                              onPressed: () {
                                searchController.clear();
                                setModalState(() => query = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.backgroundTertiary,
                      border: const OutlineInputBorder(
                        borderRadius: AppTheme.radiusMd,
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: q.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.compass, size: 42, color: AppTheme.textMuted),
                                const SizedBox(height: 10),
                                Text(
                                  'חפש בכל נתוני הפלוגה ממקום אחד',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'חיילים (${soldiers.length}) • פניות (${cases.length}) • תרופות (${MedicationGuideScreen.medications.length}) • ציוד (${equipment.length})',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
                                ),
                              ],
                            ),
                          )
                        : !hasAnyResults
                            ? Center(
                                child: Text(
                                  'לא נמצאו תוצאות עבור "$query"',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                              )
                            : ListView(
                                children: [
                                  if (matchedSoldiers.isNotEmpty) ...[
                                    _buildSectionHeader('חיילים במצבת (${matchedSoldiers.length})', LucideIcons.users),
                                    ...matchedSoldiers.map((s) {
                                      return ListTile(
                                        dense: true,
                                        leading: CircleAvatar(
                                          radius: 17,
                                          backgroundColor: s.hasAllergies
                                              ? AppTheme.criticalRed.withValues(alpha: 0.16)
                                              : AppTheme.primaryGreen.withValues(alpha: 0.16),
                                          child: Icon(
                                            s.hasAllergies ? LucideIcons.alertTriangle : LucideIcons.user,
                                            size: 15,
                                            color: s.hasAllergies ? AppTheme.criticalRed : AppTheme.primaryGreen,
                                          ),
                                        ),
                                        title: Text(
                                          s.name,
                                          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          [
                                            if (s.personalNumber != null && s.personalNumber!.isNotEmpty)
                                              'מ.א ${s.personalNumber}',
                                            if (s.platoon != null && s.platoon!.isNotEmpty)
                                              PlatoonHelper.formatDisplay(s.platoon),
                                            if (s.hasAllergies) 'רגישות: ${s.allergies}',
                                          ].join(' • '),
                                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                        ),
                                        trailing: Icon(LucideIcons.chevronLeft, size: 16, color: AppTheme.textSecondary),
                                        onTap: () {
                                          Navigator.pop(sheetCtx);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => SoldierMedicalHistoryScreen(soldier: s),
                                            ),
                                          );
                                        },
                                      );
                                    }),
                                    const SizedBox(height: 10),
                                  ],
                                  if (matchedCases.isNotEmpty) ...[
                                    _buildSectionHeader('פניות רפואיות (${matchedCases.length})', LucideIcons.clipboardList),
                                    ...matchedCases.map((c) {
                                      final s = soldierMap[c.soldierId];
                                      final isCompleted = c.status == 'COMPLETED';
                                      return ListTile(
                                        dense: true,
                                        leading: CircleAvatar(
                                          radius: 17,
                                          backgroundColor: isCompleted
                                              ? AppTheme.successGreen.withValues(alpha: 0.15)
                                              : AppTheme.warningAmber.withValues(alpha: 0.15),
                                          child: Icon(
                                            isCompleted ? LucideIcons.checkCircle2 : LucideIcons.clock,
                                            size: 15,
                                            color: isCompleted ? AppTheme.successGreen : AppTheme.warningAmber,
                                          ),
                                        ),
                                        title: Text(
                                          s?.name ?? 'חייל',
                                          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          c.description ?? 'ללא תיאור',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                        ),
                                        trailing: Icon(LucideIcons.chevronLeft, size: 16, color: AppTheme.textSecondary),
                                        onTap: () {
                                          Navigator.pop(sheetCtx);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => MedicalCaseDetailScreen(medicalCase: c),
                                            ),
                                          );
                                        },
                                      );
                                    }),
                                    const SizedBox(height: 10),
                                  ],
                                  if (matchedMeds.isNotEmpty) ...[
                                    _buildSectionHeader('מדריך תרופות ומינונים (${matchedMeds.length})', LucideIcons.pill),
                                    ...matchedMeds.map((med) {
                                      return ListTile(
                                        dense: true,
                                        leading: CircleAvatar(
                                          radius: 17,
                                          backgroundColor: AppTheme.infoBlue.withValues(alpha: 0.15),
                                          child: Icon(LucideIcons.pill, size: 15, color: AppTheme.infoBlue),
                                        ),
                                        title: Text(
                                          '${med.name} (${med.activeIngredient})',
                                          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          '${med.category} • מינון: ${med.adultDose}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                        ),
                                        trailing: Icon(LucideIcons.chevronLeft, size: 16, color: AppTheme.textSecondary),
                                        onTap: () {
                                          Navigator.pop(sheetCtx);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => MedicationGuideScreen(initialMedicationId: med.id),
                                            ),
                                          );
                                        },
                                      );
                                    }),
                                    const SizedBox(height: 10),
                                  ],
                                  if (matchedEquipment.isNotEmpty) ...[
                                    _buildSectionHeader('ציוד ומלאי (${matchedEquipment.length})', LucideIcons.package),
                                    ...matchedEquipment.map((eq) {
                                      final isMissing = eq.quantity < eq.minimumRequired;
                                      final loc = eq.isCompanyBox ? 'ארגז חופ"ל' : 'ווסט חובש';
                                      return ListTile(
                                        dense: true,
                                        leading: CircleAvatar(
                                          radius: 17,
                                          backgroundColor: isMissing
                                              ? AppTheme.criticalRed.withValues(alpha: 0.15)
                                              : AppTheme.primaryGreen.withValues(alpha: 0.15),
                                          child: Icon(
                                            LucideIcons.package,
                                            size: 15,
                                            color: isMissing ? AppTheme.criticalRed : AppTheme.primaryGreen,
                                          ),
                                        ),
                                        title: Text(
                                          eq.name,
                                          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          '$loc • במלאי: ${eq.quantity} (תקן: ${eq.minimumRequired})',
                                          style: TextStyle(
                                            color: isMissing ? AppTheme.criticalRed : AppTheme.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ],
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryGreen),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}


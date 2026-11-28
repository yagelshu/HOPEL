import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/core/services/battalion_staff_service.dart';
import 'package:chopel_app/core/utils/battalion_medic_helper.dart';
import 'package:chopel_app/core/utils/doctor_consult_helper.dart';
import 'package:chopel_app/core/utils/platoon_helper.dart';
import 'package:chopel_app/features/dashboard/providers.dart';
import 'package:chopel_app/features/medical_cases/medical_case_detail_screen.dart';
import 'package:chopel_app/features/medical_cases/providers.dart';
import 'package:chopel_app/models/medical_case.dart';
import 'package:chopel_app/models/soldier.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_bottom_sheet.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:chopel_app/theme/components/hopal_text_field.dart';

class MatabQueueCard extends StatelessWidget {
  final List<MedicalCase> allCases;
  final List<Soldier> soldiers;

  const MatabQueueCard({
    super.key,
    required this.allCases,
    required this.soldiers,
  });

  static const List<String> _decisionPresets = [
    'כשיר לפעילות מלאה',
    "ימי ב' (מנוחה במוצב)",
    "ימי ג' (מנוחה בבית)",
    'פטור ממאמץ / משקלים',
    'פטור נעליים / עמידה',
    'טיפול תרופתי / מרשם',
    'הפניה למיון / מומחה',
  ];

  static bool _isExemptionDecision(String decision) {
    return decision.contains("ימי ב'") ||
        decision.contains("ימי ג'") ||
        decision.contains('פטור');
  }

  /// Shows a tactical dialog to record the Matab doctor/paramedic's examination decision & exemption duration in 1 tap.
  static Future<void> showDoctorDecisionSheet(
    BuildContext context, {
    required WidgetRef ref,
    required MedicalCase medicalCase,
    required Soldier? soldier,
  }) async {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}

    String selectedDecision = _decisionPresets.first;
    int selectedDays = 2;
    bool closeCaseAfter = false;
    final notesController = TextEditingController();
    final soldierName = soldier?.name ?? 'חייל';

    await HopalBottomSheet.show(
      context: context,
      title: 'סיכום בדיקת מט"ב – $soldierName',
      child: StatefulBuilder(
        builder: (sheetCtx, setModalState) {
          final needsDuration = _isExemptionDecision(selectedDecision);

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (soldier != null && soldier.hasAllergies) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.criticalRed.withValues(alpha: 0.14),
                      borderRadius: AppTheme.radiusSm,
                      border: Border.all(color: AppTheme.criticalRed.withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.shieldAlert, size: 16, color: AppTheme.criticalRed),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'רגישות מדווחת לחייל: ${soldier.allergies}',
                            style: TextStyle(
                              color: AppTheme.criticalRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Text(
                  '1. החלטת רופא / פראמדיק:',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _decisionPresets.map((preset) {
                    final isSelected = selectedDecision == preset;
                    final isExemption = _isExemptionDecision(preset);
                    final activeColor = isExemption ? AppTheme.warningAmber : AppTheme.primaryGreen;
                    return ChoiceChip(
                      label: Text(preset),
                      selected: isSelected,
                      onSelected: (_) {
                        setModalState(() {
                          selectedDecision = preset;
                          if (!isExemption && preset == 'כשיר לפעילות מלאה') {
                            closeCaseAfter = true;
                          } else if (isExemption) {
                            closeCaseAfter = false;
                          }
                        });
                      },
                      selectedColor: activeColor.withValues(alpha: 0.2),
                      backgroundColor: AppTheme.backgroundPrimary,
                      checkmarkColor: activeColor,
                      labelStyle: TextStyle(
                        color: isSelected ? activeColor : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: isSelected ? activeColor : AppTheme.borderSubtle,
                      ),
                    );
                  }).toList(),
                ),
                if (needsDuration) ...[
                  const SizedBox(height: 14),
                  Text(
                    '2. משך פטור / ימי מנוחה (חישוב תוקף אוטומטי):',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      {'label': 'יום 1 (24ש\')', 'days': 1},
                      {'label': 'יומיים (48ש\')', 'days': 2},
                      {'label': '3 ימים (72ש\')', 'days': 3},
                      {'label': '5 ימים', 'days': 5},
                      {'label': '7 ימים', 'days': 7},
                      {'label': 'ללא הגבלת ימים', 'days': 0},
                    ].map((opt) {
                      final days = opt['days'] as int;
                      final label = opt['label'] as String;
                      final isSelected = selectedDays == days;
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (_) => setModalState(() => selectedDays = days),
                        selectedColor: AppTheme.infoBlue.withValues(alpha: 0.2),
                        backgroundColor: AppTheme.backgroundPrimary,
                        checkmarkColor: AppTheme.infoBlue,
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.infoBlue : AppTheme.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppTheme.infoBlue : AppTheme.borderSubtle,
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 14),
                HopalTextField(
                  controller: notesController,
                  hint: 'הנחיות נוספות של הרופא (מינון תרופה, ביקורת, דגשים...)',
                  icon: LucideIcons.stethoscope,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundPrimary,
                    borderRadius: AppTheme.radiusMd,
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: SwitchListTile.adaptive(
                    dense: true,
                    activeThumbColor: AppTheme.successGreen,
                    title: Text(
                      closeCaseAfter
                          ? 'סגור פנייה זו כ"טיפול הושלם"'
                          : 'השאר פנייה פתוחה במעקב חופ"ל (מומלץ לפטור/תרופות)',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    subtitle: Text(
                      closeCaseAfter
                          ? 'החייל יוסר מתור המט"ב והתיק יעבור להיסטוריה'
                          : 'החייל יוסר מתור המט"ב ויופיע במצבת הפטורים/מעקבים',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                    value: closeCaseAfter,
                    onChanged: (val) => setModalState(() => closeCaseAfter = val),
                  ),
                ),
                const SizedBox(height: 16),
                HopalButton(
                  label: 'שמור החלטת מט"ב בתיק החייל',
                  icon: LucideIcons.checkCircle2,
                  isExpanded: true,
                  onPressed: () async {
                    final stamp = BattalionStaffService.formatMatabDecisionStamp(
                      decision: selectedDecision,
                      exemptionDays: needsDuration && selectedDays > 0 ? selectedDays : null,
                      notes: notesController.text,
                    );
                    final cleanedDesc = BattalionStaffService.stripMatabQueueTags(medicalCase.description);
                    final updatedDesc = cleanedDesc.isEmpty ? stamp : '$cleanedDesc\n$stamp';

                    final map = medicalCase.toMap();
                    map['description'] = updatedDesc;
                    map['category'] = needsDuration
                        ? BattalionStaffService.exemptionCategory
                        : 'שגרת מרפאה';
                    if (closeCaseAfter) {
                      map['status'] = 'COMPLETED';
                      map['closed_date'] = DateTime.now().toIso8601String();
                    }
                    map['updated_date'] = DateTime.now().toIso8601String();

                    await ref
                        .read(medicalCasesProvider.notifier)
                        .upsertCaseOptimistically(MedicalCase.fromMap(map));
                    ref.invalidate(dashboardMetricsProvider);

                    if (sheetCtx.mounted) {
                      Navigator.pop(sheetCtx);
                    }
                    if (context.mounted) {
                      HopalFeedback.showSuccess(
                        context,
                        'סיכום מט"ב נשמר עבור $soldierName',
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static void showQueueSheet(
    BuildContext context, {
    required List<MedicalCase> allCases,
    required List<Soldier> soldiers,
  }) {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}

    final unitName = AuthService().currentUser?.unitName;

    HopalBottomSheet.show(
      context: context,
      title: 'מסדר מט"ב – חיילים לבדיקה היום',
      child: Consumer(
        builder: (sheetCtx, ref, _) {
          final liveCases = ref.watch(medicalCasesProvider).value ?? allCases;
          final liveSoldiers = ref.watch(soldiersProvider).value ?? soldiers;
          final queueCases = liveCases.where(BattalionStaffService.isCaseInMatabQueue).toList();
          final soldierMap = {for (final s in liveSoldiers) s.id: s};

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'רשימת החיילים ששובצו לבדיקת מט"ב (${queueCases.length}). בזמן המסדר ניתן לתעד החלטת רופא ופטורים בלחיצה על "סיכום מט"ב" ליד כל חייל:',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: AppTheme.spacing16),
                if (queueCases.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing20),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundPrimary,
                      borderRadius: AppTheme.radiusMd,
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Column(
                      children: [
                        Icon(LucideIcons.stethoscope, color: AppTheme.textMuted, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'אין כרגע חיילים המשובצים למסדר מט"ב',
                          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'כדי לשבץ חייל, סמן "שבץ למסדר מט"ב" בעת פתיחת פנייה חדשה או מתוך כרטיס הפנייה.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                else ...[
                  ...queueCases.map((c) {
                    final s = soldierMap[c.soldierId];
                    final sName = s?.name ?? 'חייל';
                    final isUrgent = c.severity == 'דחוף' || c.severity == 'קריטי';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundPrimary,
                        borderRadius: AppTheme.radiusMd,
                        border: Border.all(
                          color: isUrgent
                              ? AppTheme.warningAmber.withValues(alpha: 0.6)
                              : AppTheme.borderSubtle,
                        ),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: isUrgent
                                  ? AppTheme.warningAmber.withValues(alpha: 0.18)
                                  : AppTheme.infoBlue.withValues(alpha: 0.18),
                              child: Icon(
                                LucideIcons.stethoscope,
                                size: 16,
                                color: isUrgent ? AppTheme.warningAmber : AppTheme.infoBlue,
                              ),
                            ),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    sName,
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (s?.platoon != null && s!.platoon!.trim().isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.backgroundTertiary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      PlatoonHelper.formatDisplay(s.platoon),
                                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                                    ),
                                  ),
                                ],
                                if (s != null && s.hasAllergies) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.criticalRed.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'רגישות: ${s.allergies}',
                                      style: TextStyle(
                                        color: AppTheme.criticalRed,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              c.description ?? 'ללא תיאור',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                            trailing: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryGreen,
                                side: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(LucideIcons.clipboardCheck, size: 14),
                              label: const Text(
                                'סיכום מט"ב',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () => showDoctorDecisionSheet(
                                sheetCtx,
                                ref: ref,
                                medicalCase: c,
                                soldier: s,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => MedicalCaseDetailScreen(medicalCase: c)),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: AppTheme.spacing16),
                  HopalButton(
                    label: 'שלח רשימת מסדר מט"ב למט"ב התורן (WhatsApp)',
                    icon: LucideIcons.stethoscope,
                    onPressed: () async {
                      Navigator.pop(context);
                      final msg = BattalionStaffService.buildMatabQueueMessage(
                        cases: liveCases,
                        soldiers: liveSoldiers,
                        unitName: unitName,
                      );
                      await DoctorConsultHelper.sendMessageToMatab(context, msg);
                    },
                  ),
                  const SizedBox(height: 8),
                  HopalButton(
                    label: 'שלח רשימת מסדר מט"ב לחוג"ד / מחליף',
                    icon: LucideIcons.send,
                    variant: HopalButtonVariant.secondary,
                    onPressed: () async {
                      Navigator.pop(context);
                      final msg = BattalionStaffService.buildMatabQueueMessage(
                        cases: liveCases,
                        soldiers: liveSoldiers,
                        unitName: unitName,
                      );
                      await BattalionMedicHelper.sendReportToHogad(context, msg);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      final msg = BattalionStaffService.buildMatabQueueMessage(
                        cases: liveCases,
                        soldiers: liveSoldiers,
                        unitName: unitName,
                      );
                      await Clipboard.setData(ClipboardData(text: msg));
                      if (context.mounted) {
                        Navigator.pop(context);
                        HopalFeedback.showSuccess(context, 'רשימת מסדר מט"ב הועתקה ללוח');
                      }
                    },
                    icon: Icon(LucideIcons.copy, size: 15, color: AppTheme.textSecondary),
                    label: Text('העתק רשימה ללוח', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final queueCases = allCases.where(BattalionStaffService.isCaseInMatabQueue).toList();
    if (queueCases.isEmpty) return const SizedBox.shrink();

    final soldierMap = {for (final s in soldiers) s.id: s};
    final namesPreview = queueCases
        .map((c) => soldierMap[c.soldierId]?.name ?? 'חייל')
        .toSet()
        .take(3)
        .join(', ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, AppTheme.spacing12, AppTheme.spacing16, 0),
      child: HopalCard(
        borderColor: AppTheme.infoBlue.withValues(alpha: 0.55),
        padding: const EdgeInsets.all(AppTheme.spacing12),
        onTap: () => showQueueSheet(context, allCases: allCases, soldiers: soldiers),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing8),
              decoration: BoxDecoration(
                color: AppTheme.infoBlue.withValues(alpha: 0.15),
                borderRadius: AppTheme.radiusMd,
              ),
              child: Icon(LucideIcons.stethoscope, color: AppTheme.infoBlue, size: 22),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'מסדר מט"ב היום (חיילים לבדיקה)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.infoBlue,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppTheme.infoBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${queueCases.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ממתינים לבדיקה: $namesPreview${queueCases.length > 3 ? '...' : ''} • לחץ לשליחה למט"ב',
                    style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronLeft, color: AppTheme.infoBlue, size: 18),
          ],
        ),
      ),
    );
  }
}


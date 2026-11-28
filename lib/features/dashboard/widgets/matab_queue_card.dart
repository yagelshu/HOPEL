import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/core/services/battalion_staff_service.dart';
import 'package:chopel_app/core/utils/battalion_medic_helper.dart';
import 'package:chopel_app/core/utils/doctor_consult_helper.dart';
import 'package:chopel_app/core/utils/platoon_helper.dart';
import 'package:chopel_app/features/medical_cases/medical_case_detail_screen.dart';
import 'package:chopel_app/models/medical_case.dart';
import 'package:chopel_app/models/soldier.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_bottom_sheet.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';

class MatabQueueCard extends StatelessWidget {
  final List<MedicalCase> allCases;
  final List<Soldier> soldiers;

  const MatabQueueCard({
    super.key,
    required this.allCases,
    required this.soldiers,
  });

  static void showQueueSheet(
    BuildContext context, {
    required List<MedicalCase> allCases,
    required List<Soldier> soldiers,
  }) {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}

    final queueCases = allCases.where(BattalionStaffService.isCaseInMatabQueue).toList();
    final soldierMap = {for (final s in soldiers) s.id: s};
    final unitName = AuthService().currentUser?.unitName;

    HopalBottomSheet.show(
      context: context,
      title: 'מסדר מט"ב – חיילים לבדיקה היום (${queueCases.length})',
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'רשימת החיילים ששובצו לבדיקת מט"ב (רופא / פראמדיק). ניתן לשלוח את הרשימה המסודרת ב-WhatsApp למט"ב התורן או לחוג"ד:',
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
                      'כדי לשבץ חייל, סמן "שבץ למסדר מט"ב" בעת פתיחת פנייה חדשה או מתוך מסך פרטי פנייה קיימת.',
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
                  child: ListTile(
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
                    trailing: Icon(LucideIcons.chevronLeft, size: 16, color: AppTheme.textSecondary),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MedicalCaseDetailScreen(medicalCase: c)),
                      );
                    },
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
                    cases: allCases,
                    soldiers: soldiers,
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
                    cases: allCases,
                    soldiers: soldiers,
                    unitName: unitName,
                  );
                  await BattalionMedicHelper.sendReportToHogad(context, msg);
                },
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  final msg = BattalionStaffService.buildMatabQueueMessage(
                    cases: allCases,
                    soldiers: soldiers,
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


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/core/services/outbreak_radar_service.dart';
import 'package:chopel_app/core/utils/battalion_medic_helper.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_bottom_sheet.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';

class OutbreakRadarCard extends StatelessWidget {
  final List<OutbreakAlert> alerts;

  const OutbreakRadarCard({super.key, required this.alerts});

  void _showAlertDetails(BuildContext context, OutbreakAlert alert) {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}

    HopalBottomSheet.show(
      context: context,
      title: 'התרעת מודיעין רפואי',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            decoration: BoxDecoration(
              color: AppTheme.criticalRed.withValues(alpha: 0.12),
              borderRadius: AppTheme.radiusMd,
              border: Border.all(color: AppTheme.criticalRed.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, color: AppTheme.criticalRed, size: 24),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'חלון זמן: ${alert.windowHours} שעות אחרונות',
                        style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),

          Text('המלצות פעולה לחופ"ל בשטח:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Text(
            alert.recommendation,
            style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary, height: 1.45),
          ),
          const SizedBox(height: AppTheme.spacing16),

          Text('חיילים מעורבים שנבדקו (${alert.affectedSoldierNames.length}):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: alert.affectedSoldierNames.map((name) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundSecondary,
                  borderRadius: AppTheme.radiusSm,
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Text(name, style: TextStyle(fontSize: 12.5, color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
              );
            }).toList(),
          ),
          const SizedBox(height: AppTheme.spacing24),

          HopalButton(
            label: 'שלח דיווח מודיעין רפואי לחוג"ד / רופא',
            icon: LucideIcons.send,
            onPressed: () async {
              Navigator.pop(context);
              final report = OutbreakRadarService.formatReportForDoctor(alert);
              await BattalionMedicHelper.sendReportToHogad(context, report);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    final topAlert = alerts.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, AppTheme.spacing16, AppTheme.spacing16, 0),
      child: HopalCard(
        borderColor: AppTheme.criticalRed.withValues(alpha: 0.6),
        padding: const EdgeInsets.all(AppTheme.spacing12),
        onTap: () => _showAlertDetails(context, topAlert),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing8),
              decoration: BoxDecoration(
                color: AppTheme.criticalRed.withValues(alpha: 0.15),
                borderRadius: AppTheme.radiusMd,
              ),
              child: Icon(LucideIcons.radar, color: AppTheme.criticalRed, size: 22),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'מכ"ם תחלואה פלוגתי',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.criticalRed),
                      ),
                      if (alerts.length > 1) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.criticalRed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '+${alerts.length - 1}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    topAlert.title,
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronLeft, color: AppTheme.criticalRed, size: 18),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/core/services/follow_up_reminder_service.dart';
import 'package:chopel_app/features/medical_cases/providers.dart';
import 'package:chopel_app/models/medical_case.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';

class DashboardFollowUpsWidget extends ConsumerStatefulWidget {
  const DashboardFollowUpsWidget({super.key});

  @override
  ConsumerState<DashboardFollowUpsWidget> createState() => _DashboardFollowUpsWidgetState();
}

class _DashboardFollowUpsWidgetState extends ConsumerState<DashboardFollowUpsWidget> {
  List<FollowUpReminder> _pendingReminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await FollowUpReminderService.getPendingReminders();
    if (mounted) {
      setState(() {
        _pendingReminders = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _appendFollowUpToMedicalCase(
    FollowUpReminder reminder,
    String measuredVal,
  ) async {
    try {
      final cases = ref.read(medicalCasesProvider).value ?? const <MedicalCase>[];
      MedicalCase? targetCase;
      if (reminder.caseId.isNotEmpty) {
        targetCase = cases.where((c) => c.id == reminder.caseId).firstOrNull;
      }
      targetCase ??= cases
          .where((c) =>
              c.soldierId == reminder.soldierId &&
              c.status != 'COMPLETED' &&
              c.status != 'CLOSED')
          .firstOrNull;

      if (targetCase == null) return;

      final now = DateTime.now().toLocal();
      final dd = now.day.toString().padLeft(2, '0');
      final mm = now.month.toString().padLeft(2, '0');
      final hh = now.hour.toString().padLeft(2, '0');
      final min = now.minute.toString().padLeft(2, '0');
      final medicName = AuthService().effectiveUserName;

      final entry = '📌 [$dd/$mm $hh:$min • $medicName]: ${reminder.type} — $measuredVal';
      final prevDesc = (targetCase.description ?? '').trim();
      final nextDesc = prevDesc.isEmpty ? entry : '$prevDesc\n$entry';

      final map = targetCase.toMap();
      map['description'] = nextDesc;
      map['updated_date'] = DateTime.now().toIso8601String();

      await ref
          .read(medicalCasesProvider.notifier)
          .upsertCaseOptimistically(MedicalCase.fromMap(map));
    } catch (_) {}
  }

  Future<void> _quickComplete(FollowUpReminder reminder) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundSecondary,
        title: Text('סיום מעקב: ${reminder.soldierName}', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${reminder.type}:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              autofocus: true,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'הזן מדדים שנמדדו (לדוגמה: 36.8°C / ל"ד תקין)',
                hintStyle: TextStyle(color: AppTheme.textMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'הנתון יתועד אוטומטית גם בציר הזמן של התיק הרפואי של החייל.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ביטול', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            onPressed: () async {
              Navigator.pop(ctx);
              final val = controller.text.trim().isEmpty ? 'בוצע ותקין' : controller.text.trim();
              await FollowUpReminderService.completeReminder(
                reminder.id,
                measuredValue: val,
              );
              await _appendFollowUpToMedicalCase(reminder, val);
              await _load();
              if (mounted) {
                HopalFeedback.showSuccess(context, 'המעקב סומן כבוצע ותועד בתיק החייל');
              }
            },
            child: const Text('סמן כבוצע'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _pendingReminders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, AppTheme.spacing24, AppTheme.spacing16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.bellRing, size: 18, color: AppTheme.warningAmber),
              const SizedBox(width: 8),
              Text(
                'מעקבים ומדדים ממתינים (${_pendingReminders.length})',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Column(
            children: _pendingReminders.take(3).map((r) {
              final isOverdue = r.isOverdue;
              final timeStr = DateFormat('HH:mm').format(r.dueTime);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: HopalCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  borderColor: isOverdue ? AppTheme.criticalRed : AppTheme.borderSubtle,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (isOverdue ? AppTheme.criticalRed : AppTheme.warningAmber).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isOverdue ? LucideIcons.alertTriangle : LucideIcons.clock,
                          size: 16,
                          color: isOverdue ? AppTheme.criticalRed : AppTheme.warningAmber,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${r.soldierName} • ${r.type}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isOverdue ? 'מועד שחלף: $timeStr (נדרש ביצוע מיידי)' : 'מתוכנן לשעה: $timeStr',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isOverdue ? AppTheme.criticalRed : AppTheme.textSecondary,
                                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryGreen,
                          side: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () => _quickComplete(r),
                        child: const Text('בוצע', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}


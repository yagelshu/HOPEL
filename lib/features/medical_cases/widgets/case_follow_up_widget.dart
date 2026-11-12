import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:chopel_app/core/services/follow_up_reminder_service.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';

class CaseFollowUpWidget extends StatefulWidget {
  final String caseId;
  final String soldierId;
  final String soldierName;

  const CaseFollowUpWidget({
    super.key,
    required this.caseId,
    required this.soldierId,
    required this.soldierName,
  });

  @override
  State<CaseFollowUpWidget> createState() => _CaseFollowUpWidgetState();
}

class _CaseFollowUpWidgetState extends State<CaseFollowUpWidget> {
  List<FollowUpReminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final list = await FollowUpReminderService.getRemindersForCase(widget.caseId);
    if (mounted) {
      setState(() {
        _reminders = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddReminderDialog() async {
    final types = [
      'מדידת חום חוזרת',
      'בדיקת לחץ דם ומדדים',
      'מנת תרופה הבאה',
      'ביקורת פצע / חבישה',
    ];

    String selectedType = types.first;
    int selectedHours = 2;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.backgroundSecondary,
            title: Row(
              children: [
                Icon(LucideIcons.bellRing, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text('תזכורת מעקב לחייל', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('סוג המעקב הנדרש:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  dropdownColor: AppTheme.backgroundSecondary,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: types.map((t) => DropdownMenuItem(value: t, child: Text(t, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 16),
                Text('מועד הביצוע:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [1, 2, 4, 8, 24].map((h) {
                    final isSel = selectedHours == h;
                    final label = h == 1 ? 'שעה' : (h == 24 ? 'מחר' : '$h שעות');
                    return ChoiceChip(
                      label: Text(label, style: TextStyle(fontSize: 12, color: isSel ? AppTheme.onPrimaryGreen : AppTheme.textSecondary)),
                      selected: isSel,
                      selectedColor: AppTheme.primaryGreen,
                      backgroundColor: AppTheme.backgroundTertiary,
                      onSelected: (sel) {
                        if (sel) setDialogState(() => selectedHours = h);
                      },
                    );
                  }).toList(),
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
                  final reminder = FollowUpReminder(
                    id: const Uuid().v4(),
                    caseId: widget.caseId,
                    soldierId: widget.soldierId,
                    soldierName: widget.soldierName,
                    type: selectedType,
                    dueTime: DateTime.now().add(Duration(hours: selectedHours)),
                  );
                  await FollowUpReminderService.addReminder(reminder);
                  await _loadReminders();
                  if (mounted) {
                    HopalFeedback.showSuccess(context, 'תזכורת המעקב נקבעה בהצלחה');
                  }
                },
                child: const Text('קבע תזכורת'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _completeReminder(FollowUpReminder reminder) async {
    final valueController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundSecondary,
        title: Text('תיעוד ביצוע מעקב', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${reminder.type} עבור ${reminder.soldierName}:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: valueController,
              autofocus: true,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'לדוגמה: 36.9°C, לחץ דם 120/80, תקין...',
                hintStyle: TextStyle(color: AppTheme.textMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
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
              await FollowUpReminderService.completeReminder(
                reminder.id,
                measuredValue: valueController.text.trim().isEmpty ? 'בוצע' : valueController.text.trim(),
              );
              await _loadReminders();
              if (mounted) {
                HopalFeedback.showSuccess(context, 'המעקב סומן כבוצע ותועד');
              }
            },
            child: const Text('שמור ביצוע'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('תזכורות מעקב ומדדים', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            TextButton.icon(
              icon: const Icon(LucideIcons.plus, size: 15),
              label: const Text('הוסף מעקב', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _showAddReminderDialog,
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_reminders.isEmpty)
          HopalCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(LucideIcons.clock, color: AppTheme.textMuted, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'אין תזכורות מעקב פעילות לפנייה זו. קבע תזכורת למדידת חום, לחץ דם או מנת תרופה הבאה.',
                    style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: _reminders.map((r) {
              final isDone = r.isCompleted;
              final isOverdue = r.isOverdue;
              final timeStr = DateFormat('dd/MM HH:mm').format(r.dueTime);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: HopalCard(
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  borderColor: isDone
                      ? AppTheme.borderSubtle
                      : (isOverdue ? AppTheme.criticalRed : AppTheme.primaryGreen.withValues(alpha: 0.5)),
                  child: Row(
                    children: [
                      Icon(
                        isDone ? LucideIcons.checkCircle2 : (isOverdue ? LucideIcons.alertCircle : LucideIcons.hourglass),
                        color: isDone ? AppTheme.successGreen : (isOverdue ? AppTheme.criticalRed : AppTheme.primaryGreen),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.type,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDone ? AppTheme.textSecondary : AppTheme.textPrimary,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isDone ? 'בוצע: ${r.measuredValue ?? "מאושר"}' : 'מועד ביצוע: $timeStr ${isOverdue ? "(באיחור)" : ""}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDone ? AppTheme.successGreen : (isOverdue ? AppTheme.criticalRed : AppTheme.textSecondary),
                                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isDone)
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _completeReminder(r),
                          child: const Text('סמן כבוצע', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}


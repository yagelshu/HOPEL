import 'package:flutter/material.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HopalTimelineEvent {
  final IconData icon;
  final Color? iconColor;
  final String time;
  final String title;
  final String? actor;
  final String? result;
  final bool isLast;
  final bool isDone;
  final VoidCallback? onTap;

  HopalTimelineEvent({
    required this.icon,
    this.iconColor,
    required this.time,
    required this.title,
    this.actor,
    this.result,
    this.isLast = false,
    this.isDone = false,
    this.onTap,
  });
}

class HopalTimeline extends StatelessWidget {
  final List<HopalTimelineEvent> events;

  const HopalTimeline({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: events.map((event) => _buildTimelineRow(event)).toList(),
    );
  }

  Widget _buildTimelineRow(HopalTimelineEvent event) {
    final activeColor = event.isDone
        ? AppTheme.successGreen
        : (event.iconColor ?? AppTheme.militaryOlive);

    return GestureDetector(
      onTap: event.onTap,
      behavior: HitTestBehavior.opaque,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Time Column
            SizedBox(
              width: 50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    event.time,
                    style: TextStyle(
                      color: event.isDone ? AppTheme.textMuted : AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacing16),
            // Timeline Line & Node
            Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.only(top: AppTheme.spacing4),
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: event.isDone ? 0.22 : 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: activeColor.withValues(alpha: event.isDone ? 0.7 : 0.35),
                      width: event.isDone ? 1.5 : 1.0,
                    ),
                  ),
                  child: Icon(
                    event.isDone ? LucideIcons.check : event.icon,
                    size: 14,
                    color: activeColor,
                  ),
                ),
                if (!event.isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
                      decoration: BoxDecoration(
                        color: AppTheme.borderStrong,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: AppTheme.spacing16),
              ],
            ),
            const SizedBox(width: AppTheme.spacing16),
            // Content Column
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  top: AppTheme.spacing4,
                  bottom: event.isLast ? 0 : AppTheme.spacing24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        color: event.isDone ? AppTheme.textMuted : AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        decoration: event.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (event.actor != null || event.result != null)
                      const SizedBox(height: AppTheme.spacing4),
                    if (event.actor != null)
                      Text(
                        event.actor!,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (event.result != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppTheme.spacing4),
                        child: Text(
                          event.result!,
                          style: TextStyle(
                            color: AppTheme.militaryOlive,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

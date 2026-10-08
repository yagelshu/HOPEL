import 'package:flutter/material.dart';
import 'package:chopel_app/theme/app_theme.dart';

enum HopalStatusBadgeVariant { success, warning, critical, info, neutral }

class HopalStatusBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final HopalStatusBadgeVariant variant;

  const HopalStatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.variant = HopalStatusBadgeVariant.neutral,
  });

  @override
  Widget build(BuildContext context) {
    Color color;

    switch (variant) {
      case HopalStatusBadgeVariant.success:
        color = AppTheme.successGreen;
        break;
      case HopalStatusBadgeVariant.warning:
        color = AppTheme.warningAmber;
        break;
      case HopalStatusBadgeVariant.critical:
        color = AppTheme.criticalRed;
        break;
      case HopalStatusBadgeVariant.info:
        color = AppTheme.infoBlue;
        break;
      case HopalStatusBadgeVariant.neutral:
        color = AppTheme.textMuted;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppTheme.radiusPill,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: AppTheme.spacing4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HopalFeedback {
  static void showSuccess(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      icon: LucideIcons.checkCircle2,
      iconColor: AppTheme.successGreen,
    );
  }

  static void showError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.radiusLg,
          side: BorderSide(color: AppTheme.borderStrong),
        ),
        title: Row(
          children: [
            Icon(LucideIcons.alertCircle, color: AppTheme.criticalRed),
            const SizedBox(width: 8),
            Text('שים לב', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, height: 1.45),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: AppTheme.onPrimaryGreen,
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('הבנתי', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      icon: LucideIcons.info,
      iconColor: AppTheme.infoBlue,
    );
  }

  static void _show({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color iconColor,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing12),
          decoration: BoxDecoration(
            color: AppTheme.backgroundSecondary,
            borderRadius: AppTheme.radiusMd,
            border: Border.all(color: AppTheme.borderStrong),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppTheme.spacing16),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

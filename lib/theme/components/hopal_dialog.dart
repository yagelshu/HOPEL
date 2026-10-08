import 'package:flutter/material.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';

class HopalDialog {
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'אישור',
    String cancelLabel = 'ביטול',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _HopalDialogContent(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
  }
}

class _HopalDialogContent extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  const _HopalDialogContent({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDestructive,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.backgroundSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.spacing16)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppTheme.spacing32),
            Row(
              children: [
                Expanded(
                  child: HopalButton(
                    label: cancelLabel,
                    onPressed: () => Navigator.pop(context, false),
                    variant: HopalButtonVariant.secondary,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: HopalButton(
                    label: confirmLabel,
                    onPressed: () => Navigator.pop(context, true),
                    variant: isDestructive ? HopalButtonVariant.destructive : HopalButtonVariant.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

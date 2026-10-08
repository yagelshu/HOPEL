import 'package:flutter/material.dart';
import 'package:chopel_app/theme/app_theme.dart';

class HopalBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (context) => _HopalBottomSheetContent(
        title: title,
        child: child,
      ),
    );
  }
}

class _HopalBottomSheetContent extends StatelessWidget {
  final String title;
  final Widget child;

  const _HopalBottomSheetContent({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Determine bottom padding for safe area and keyboard
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: AppTheme.spacing12, bottom: AppTheme.spacing16),
              decoration: BoxDecoration(
                color: AppTheme.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Divider(height: 1, color: AppTheme.borderSubtle),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppTheme.spacing24,
                right: AppTheme.spacing24,
                top: AppTheme.spacing24,
                bottom: bottomInset > 0 ? bottomInset + AppTheme.spacing24 : safeAreaBottom + AppTheme.spacing24,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

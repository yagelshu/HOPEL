import 'package:flutter/material.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HopalSwipeAction extends StatelessWidget {
  final Key actionKey;
  final Widget child;
  final VoidCallback onSwipeRight; // Primary Action (e.g., Close/Done)
  final VoidCallback? onSwipeLeft; // Secondary Action (e.g., Delete)
  final IconData rightIcon;
  final Color? rightColor;
  final IconData leftIcon;
  final Color? leftColor;
  final bool confirmSwipe;

  const HopalSwipeAction({
    super.key,
    required this.actionKey,
    required this.child,
    required this.onSwipeRight,
    this.onSwipeLeft,
    this.rightIcon = LucideIcons.check,
    this.rightColor,
    this.leftIcon = LucideIcons.trash2,
    this.leftColor,
    this.confirmSwipe = false,
  });

  @override
  Widget build(BuildContext context) {
    final actualRightColor = rightColor ?? AppTheme.successGreen;
    final actualLeftColor = leftColor ?? AppTheme.criticalRed;
    return Dismissible(
      key: actionKey,
      direction: onSwipeLeft != null ? DismissDirection.horizontal : DismissDirection.startToEnd,
      background: _buildBackground(actualRightColor, rightIcon, Alignment.centerLeft),
      secondaryBackground: onSwipeLeft != null ? _buildBackground(actualLeftColor, leftIcon, Alignment.centerRight) : null,
      confirmDismiss: (direction) async {
        if (!confirmSwipe) return true;
        // Optional dialog confirmation could go here
        return true;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          onSwipeRight();
        } else if (direction == DismissDirection.endToStart && onSwipeLeft != null) {
          onSwipeLeft!();
        }
      },
      child: child,
    );
  }

  Widget _buildBackground(Color color, IconData icon, Alignment alignment) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppTheme.radiusMd, // Assuming it wraps a HopalCard or HopalListTile
      ),
      child: Icon(icon, color: color),
    );
  }
}

class HopalRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const HopalRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primaryGreen,
      backgroundColor: AppTheme.backgroundTertiary,
      strokeWidth: 3,
      displacement: 40,
      child: child,
    );
  }
}

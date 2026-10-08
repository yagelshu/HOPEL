import 'package:flutter/material.dart';
import 'package:chopel_app/theme/app_theme.dart';

enum HopalButtonVariant { primary, secondary, ghost, destructive }

class HopalButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final HopalButtonVariant variant;
  final IconData? icon;
  final bool isExpanded;
  final bool isLoading;

  const HopalButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = HopalButtonVariant.primary,
    this.icon,
    this.isExpanded = false,
    this.isLoading = false,
  });

  @override
  State<HopalButton> createState() => _HopalButtonState();
}

class _HopalButtonState extends State<HopalButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
      widget.onPressed!();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null || widget.isLoading;

    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;

    switch (widget.variant) {
      case HopalButtonVariant.primary:
        backgroundColor = AppTheme.primaryGreen;
        foregroundColor = AppTheme.textPrimary;
        borderColor = AppTheme.primaryGreen;
        break;
      case HopalButtonVariant.secondary:
        backgroundColor = AppTheme.backgroundSecondary;
        foregroundColor = AppTheme.textPrimary;
        borderColor = AppTheme.borderStrong;
        break;
      case HopalButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = AppTheme.militaryOlive;
        borderColor = Colors.transparent;
        break;
      case HopalButtonVariant.destructive:
        backgroundColor = AppTheme.criticalRed.withValues(alpha: 0.1);
        foregroundColor = AppTheme.criticalRed;
        borderColor = AppTheme.criticalRed.withValues(alpha: 0.2);
        break;
    }

    if (isDisabled && widget.variant != HopalButtonVariant.ghost) {
      backgroundColor = AppTheme.backgroundTertiary;
      foregroundColor = AppTheme.textMuted;
      borderColor = AppTheme.borderSubtle;
    }

    Widget content = Row(
      mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: foregroundColor,
            ),
          )
        else if (widget.icon != null) ...[
          Icon(widget.icon, size: 20, color: foregroundColor),
          const SizedBox(width: AppTheme.spacing8),
        ],
        if (!widget.isLoading || widget.isExpanded)
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: foregroundColor,
              letterSpacing: 0.5,
            ),
          ),
      ],
    );

    Widget button = Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppTheme.radiusMd,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: content,
    );

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: button,
      ),
    );
  }
}

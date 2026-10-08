import 'package:flutter/material.dart';
import 'package:chopel_app/theme/app_theme.dart';

class HopalFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? label;

  const HopalFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
  });

  @override
  State<HopalFAB> createState() => _HopalFABState();
}

class _HopalFABState extends State<HopalFAB> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _controller.forward();
  }

  void _onPointerUp(PointerUpEvent event) {
    _controller.reverse();
    widget.onPressed();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: AppTheme.radiusXl,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: AppTheme.radiusXl,
              onTap: () {}, // Handled by Listener for precise scaling
              splashColor: Colors.white12,
              highlightColor: Colors.white10,
              child: Padding(
                padding: widget.label != null
                    ? const EdgeInsets.symmetric(horizontal: AppTheme.spacing24, vertical: AppTheme.spacing16)
                    : const EdgeInsets.all(AppTheme.spacing16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, color: Colors.white, size: 24),
                    if (widget.label != null) ...[
                      const SizedBox(width: AppTheme.spacing12),
                      Text(
                        widget.label!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

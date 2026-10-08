import 'package:flutter/material.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HopalEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const HopalEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing24),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: AppTheme.primaryGreen.withOpacity(0.8)),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scaleXY(end: 1.05, duration: 2.seconds, curve: Curves.easeInOut),
            
            const SizedBox(height: AppTheme.spacing24),
            
            Text(
              title,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ).animate().fade().slideY(begin: 0.2, end: 0, duration: 400.ms),
            
            const SizedBox(height: AppTheme.spacing8),
            
            Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ).animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),
            
            if (action != null) ...[
              const SizedBox(height: AppTheme.spacing32),
              action!.animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),
            ]
          ],
        ),
      ),
    );
  }
}

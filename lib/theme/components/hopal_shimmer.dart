import 'package:flutter/material.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HopalShimmerCard extends StatelessWidget {
  final double height;
  
  const HopalShimmerCard({super.key, this.height = 100});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.backgroundTertiary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundTertiary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                Container(
                  width: 150,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundTertiary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
    .animate(onPlay: (controller) => controller.repeat())
    .shimmer(
      duration: 1500.ms,
      color: Colors.white.withOpacity(0.05),
      angle: 1.0,
    );
  }
}

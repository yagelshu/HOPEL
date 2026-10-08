import 'package:flutter/material.dart';
import 'package:chopel_app/theme/app_theme.dart';

class HopalActionBarAction {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDestructive;

  const HopalActionBarAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isDestructive = false,
  });
}

class HopalActionBar extends StatelessWidget {
  final List<HopalActionBarAction> actions;

  const HopalActionBar({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        border: Border(
          top: BorderSide(color: AppTheme.borderSubtle),
          bottom: BorderSide(color: AppTheme.borderSubtle),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: actions.map((action) => _buildActionButton(action)).toList(),
      ),
    );
  }

  Widget _buildActionButton(HopalActionBarAction action) {
    final color = action.isDestructive ? AppTheme.criticalRed : AppTheme.militaryOlive;
    return InkWell(
      onTap: action.onPressed,
      borderRadius: AppTheme.radiusMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, color: color, size: 20),
            const SizedBox(height: AppTheme.spacing4),
            Text(
              action.label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

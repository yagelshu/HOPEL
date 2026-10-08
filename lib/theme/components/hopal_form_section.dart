import 'package:flutter/material.dart';
import 'package:chopel_app/theme/app_theme.dart';

class HopalFormSection extends StatelessWidget {
  final String? title;
  final String? description;
  final List<Widget> children;

  const HopalFormSection({
    super.key,
    this.title,
    this.description,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
            child: Text(
              title!,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: AppTheme.spacing4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
              child: Text(
                description!,
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacing12),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundSecondary,
            borderRadius: AppTheme.radiusLg,
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              final index = entry.key;
              final child = entry.value;
              return Column(
                children: [
                  child,
                  if (index < children.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: AppTheme.spacing16,
                      endIndent: AppTheme.spacing16,
                      color: AppTheme.borderSubtle,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class HopalFormToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const HopalFormToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppTheme.primaryGreen,
              activeTrackColor: AppTheme.primaryGreen.withValues(alpha: 0.5),
              inactiveThumbColor: AppTheme.textMuted,
              inactiveTrackColor: AppTheme.backgroundTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class HopalFormSelect extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const HopalFormSelect({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                ),
                const SizedBox(width: AppTheme.spacing8),
                Icon(Icons.chevron_right, color: AppTheme.militaryOlive, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

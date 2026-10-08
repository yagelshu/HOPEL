import 'package:flutter/material.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';

class HopalListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final Widget? statusBadge;
  final VoidCallback? onTap;
  final bool isUrgent;
  final IconData? leadingIcon;
  final Color? leadingIconColor;

  const HopalListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.statusBadge,
    this.onTap,
    this.isUrgent = false,
    this.leadingIcon,
    this.leadingIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return HopalCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTheme.radiusMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTheme.radiusMd,
          splashColor: Colors.white10,
          highlightColor: Colors.white12,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isUrgent)
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.criticalRed,
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(AppTheme.spacing12)),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (leadingIcon != null) ...[
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacing8),
                            decoration: BoxDecoration(
                              color: (leadingIconColor ?? AppTheme.militaryOlive).withValues(alpha: 0.15),
                              borderRadius: AppTheme.radiusSm,
                            ),
                            child: Icon(leadingIcon, color: leadingIconColor ?? AppTheme.militaryOlive, size: 20),
                          ),
                          const SizedBox(width: AppTheme.spacing16),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: title),
                                  if (statusBadge != null) ...[
                                    const SizedBox(width: AppTheme.spacing8),
                                    statusBadge!,
                                  ],
                                ],
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: AppTheme.spacing4),
                                subtitle!,
                              ],
                            ],
                          ),
                        ),
                        if (trailing != null) ...[
                          const SizedBox(width: AppTheme.spacing16),
                          trailing!,
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

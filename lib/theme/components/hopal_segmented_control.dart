import 'package:flutter/material.dart';
import 'package:chopel_app/theme/app_theme.dart';

class HopalSegmentedControl extends StatelessWidget {
  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onValueChanged;

  const HopalSegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundTertiary,
        borderRadius: AppTheme.radiusMd,
      ),
      padding: const EdgeInsets.all(AppTheme.spacing4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / segments.length;
          
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: selectedIndex * segmentWidth,
                width: segmentWidth,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundSecondary,
                    borderRadius: AppTheme.radiusSm,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: segments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final label = entry.value;
                  final isSelected = index == selectedIndex;
                  
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onValueChanged(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
                        alignment: Alignment.center,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 150),
                          style: TextStyle(
                            color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 14,
                            fontFamily: 'Heebo',
                          ),
                          child: Text(label),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

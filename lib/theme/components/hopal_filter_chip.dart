import 'package:flutter/material.dart';
import 'package:chopel_app/theme/app_theme.dart';

class HopalFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const HopalFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      child: Material(
        color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
        borderRadius: AppTheme.radiusPill,
        child: InkWell(
          onTap: onSelected,
          borderRadius: AppTheme.radiusPill,
          splashColor: Colors.white10,
          highlightColor: Colors.white12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing8),
            decoration: BoxDecoration(
              borderRadius: AppTheme.radiusPill,
              border: Border.all(
                color: isSelected ? AppTheme.primaryGreen : AppTheme.borderStrong,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HopalFilterRow extends StatelessWidget {
  final List<String> filters;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const HopalFilterRow({
    super.key,
    required this.filters,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing8),
      child: Row(
        children: filters.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;
          return Padding(
            padding: EdgeInsets.only(left: index < filters.length - 1 ? AppTheme.spacing8 : 0),
            child: HopalFilterChip(
              label: label,
              isSelected: index == selectedIndex,
              onSelected: () => onSelected(index),
            ),
          );
        }).toList(),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/features/dashboard/dashboard_screen.dart';
import 'package:chopel_app/features/medical_cases/medical_cases_list_screen.dart';
import 'package:chopel_app/features/equipment/equipment_list_screen.dart';
import 'package:chopel_app/features/learning/learning_center_screen.dart';
import 'package:chopel_app/features/notes/notes_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  final bool animateEntrance;

  const MainLayoutScreen({super.key, this.animateEntrance = false});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(animateEntrance: widget.animateEntrance),
      const MedicalCasesListScreen(),
      const EquipmentListScreen(),
      const LearningCenterScreen(),
      const NotesScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows body to scroll behind the floating nav bar
      body: _screens[_currentIndex],
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: ClipRRect(
            borderRadius: AppTheme.radiusPill,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundSecondary.withValues(alpha: 0.85),
                  borderRadius: AppTheme.radiusPill,
                  border: Border.all(color: AppTheme.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(0, LucideIcons.layoutDashboard, 'בית'),
                    _buildNavItem(1, LucideIcons.activity, 'פניות'),
                    _buildNavItem(2, LucideIcons.briefcase, 'ציוד'),
                    _buildNavItem(3, LucideIcons.bookOpen, 'למידה'),
                    _buildNavItem(4, LucideIcons.notebook, 'יומן'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppTheme.textPrimary : AppTheme.militaryOlive;

    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12, vertical: AppTheme.spacing8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: AppTheme.radiusPill,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

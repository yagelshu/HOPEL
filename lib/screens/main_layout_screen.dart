import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/features/dashboard/dashboard_screen.dart';
import 'package:chopel_app/features/dashboard/providers.dart';
import 'package:chopel_app/features/medical_cases/medical_cases_list_screen.dart';
import 'package:chopel_app/features/profile/soldiers_management_screen.dart';
import 'package:chopel_app/features/equipment/equipment_list_screen.dart';
import 'package:chopel_app/features/learning/learning_center_screen.dart';
import 'package:chopel_app/screens/profile_screen.dart';

class MainLayoutScreen extends ConsumerStatefulWidget {
  final bool animateEntrance;

  const MainLayoutScreen({super.key, this.animateEntrance = false});

  @override
  ConsumerState<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends ConsumerState<MainLayoutScreen> {
  int _currentIndex = 0;

  void _switchTab(int index) {
    if (index >= 0 && index <= 4) {
      setState(() => _currentIndex = index);
    }
  }

  Widget _buildActiveScreen() {
    switch (_currentIndex) {
      case 0:
        return DashboardScreen(
          animateEntrance: widget.animateEntrance,
          onSwitchTab: _switchTab,
        );
      case 1:
        return const MedicalCasesListScreen();
      case 2:
        return const SoldiersManagementScreen(isEmbeddedTab: true);
      case 3:
        return const EquipmentListScreen();
      case 4:
        return const LearningCenterScreen();
      default:
        return DashboardScreen(
          animateEntrance: widget.animateEntrance,
          onSwitchTab: _switchTab,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AuthService().previewRevisionNotifier,
      builder: (context, revision, _) {
        final showPreviewBanner = AuthService().isPreviewingAsCombatMedic;
        final previewName = AuthService().effectiveUserName;

        return Scaffold(
          extendBody: true, // Allows body to scroll behind the floating nav bar
          body: Column(
            children: [
              if (showPreviewBanner)
                Container(
                  width: double.infinity,
                  color: AppTheme.warningAmber.withValues(alpha: 0.18),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(LucideIcons.eye, size: 18, color: AppTheme.warningAmber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                                );
                              },
                              child: Text(
                                'תצוגת חובש: $previewName',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: AppTheme.warningAmber,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              AuthService().setCombatMedicPreview(false);
                              ref.invalidate(dashboardMetricsProvider);
                            },
                            child: const Text(
                              'חזרה לחופ"ל',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: KeyedSubtree(
                  key: ValueKey('tab_${_currentIndex}_${showPreviewBanner}_$revision'),
                  child: _buildActiveScreen(),
                ),
              ),
            ],
          ),
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
                        _buildNavItem(2, LucideIcons.users, 'חיילים'),
                        _buildNavItem(3, LucideIcons.briefcase, 'ציוד'),
                        _buildNavItem(4, LucideIcons.bookOpen, 'ידע'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppTheme.textPrimary : AppTheme.militaryOlive;

    return GestureDetector(
      onTap: () {
        try {
          HapticFeedback.selectionClick();
        } catch (_) {}
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

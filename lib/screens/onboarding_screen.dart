import 'package:flutter/material.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';

import 'package:chopel_app/features/auth/login_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  late final List<Map<String, dynamic>> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      {
        'headline': 'כל פנייה רפואית חייבת להיות מתועדת.',
        'description': 'תיעוד מסודר היום מונע טעויות ומבטיח רצף טיפולי גם מחר.',
        'mockup': _buildPremiumIcon(LucideIcons.fileText),
      },
      {
        'headline': 'כל המידע הרפואי מסודר במקום אחד.',
        'description': 'פניות, ציוד, מעקבים ונהלים — הכול נגיש תוך שניות, בדיוק כשצריך.',
        'mockup': _buildPremiumIcon(LucideIcons.layoutDashboard),
      },
      {
        'headline': 'מוכנים לכל אירוע רפואי.',
        'description': 'חופ"ל – הבית שלך לכשירות רפואית.',
        'mockup': _buildPremiumIcon(LucideIcons.shieldCheck),
      },
    ];
  }

  Widget _buildPremiumIcon(IconData icon) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            blurRadius: 60,
            spreadRadius: 20,
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, size: 80, color: AppTheme.primaryGreen),
      ),
    );
  }

  void _nextPage() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: const Cubic(0.25, 0.1, 0.25, 1.0), // Smooth, native easing
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const ClampingScrollPhysics(), // Premium feel, no bounce
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double pageOffset = 0.0;
                      if (_pageController.position.haveDimensions) {
                        pageOffset = _pageController.page! - index;
                      }

                      // Subtle fade and slight slide for content
                      final double opacity = (1 - (pageOffset.abs() * 1.5)).clamp(0.0, 1.0);
                      final double translation = pageOffset * 100.0;

                      return Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(translation, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Visual Icon Area (Breathing space)
                              Expanded(
                                flex: 11,
                                child: Center(
                                  child: _pages[index]['mockup'] as Widget,
                                ),
                              ),
                              // Storytelling Text
                              Expanded(
                                flex: 8,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing32),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        _pages[index]['headline']!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          height: 1.15,
                                          letterSpacing: -1.0,
                                        ),
                                      ),
                                      const SizedBox(height: AppTheme.spacing16),
                                      Text(
                                        _pages[index]['description']!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          color: AppTheme.textSecondary,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Progress Indicator & Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.spacing32, 0, AppTheme.spacing32, AppTheme.spacing48),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) {
                      final isActive = index == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.fastOutSlowIn,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.primaryGreen : AppTheme.primaryGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppTheme.spacing40),
                  SizedBox(
                    width: double.infinity,
                    height: 56, // Premium button height
                    child: HopalButton(
                      label: _currentIndex == _pages.length - 1 ? 'היכנס למערכת המבצעית' : 'המשך',
                      onPressed: _nextPage,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  AnimatedOpacity(
                    opacity: _currentIndex == _pages.length - 1 ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: TextButton(
                      onPressed: _currentIndex == _pages.length - 1 ? null : _goToLogin,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: Text(
                        'דלג והתחבר',
                        style: TextStyle(
                          color: AppTheme.militaryOlive,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

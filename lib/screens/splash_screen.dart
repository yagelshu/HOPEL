import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/features/dashboard/dashboard_screen.dart';
import 'package:chopel_app/screens/main_layout_screen.dart';
import 'package:chopel_app/features/auth/login_screen.dart';
import 'package:chopel_app/features/onboarding/deployment_selection_screen.dart';
import 'package:chopel_app/features/onboarding/unit_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:chopel_app/screens/biometric_lock_screen.dart';
import 'package:chopel_app/core/services/update_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isTakingLong = false;
  Timer? _longLoadTimer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Standard Entrance (Decelerate) curve: Cubic(0.0, 0.0, 0.2, 1.0)
    final curve = CurvedAnimation(
      parent: _animationController,
      curve: const Cubic(0.0, 0.0, 0.2, 1.0),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(curve);

    _animationController.forward();

    _longLoadTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isTakingLong = true);
    });

    _initializeAppData();
  }

  Future<void> _initializeAppData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      await UpdateService.checkForUpdates(context);
      
      if (AuthService().isAuthenticated) {
        await AuthService().loadProfile();
        
        final user = AuthService().currentUser;
        if (user != null && user.unitId == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UnitSelectionScreen()),
          );
        } else if (user != null && user.activeDeploymentId == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DeploymentSelectionScreen()),
          );
        } else {
          final prefs = await SharedPreferences.getInstance();
          final useBiometrics = prefs.getBool('use_biometrics') ?? false;
          
          if (useBiometrics) {
            final auth = LocalAuthentication();
            final canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();
            if (canCheck) {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const BiometricLockScreen()),
                );
                return;
              }
            }
          }
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _longLoadTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      ),
                      padding: const EdgeInsets.all(AppTheme.spacing24),
                      child: ClipRect(
                        child: Transform.scale(
                          scale: 1.05,
                          child: Image.asset(
                            'assets/icon/app_icon.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(LucideIcons.shieldCheck, size: 80, color: AppTheme.primaryGreen),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing32),
                    Text(
                      'חופ״ל',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      'מערכת לניהול רפואת פלוגה',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.militaryOlive,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
            if (_isTakingLong)
              FadeTransition(
                opacity: AlwaysStoppedAnimation(1.0),
                child: Text(
                  'טוען את סביבת העבודה...',
                  style: TextStyle(color: AppTheme.militaryOlive, fontSize: 14),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(24.0),
        child: Text(
          'v1.0.0',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.militaryOlive, fontSize: 12),
        ),
      ),
    );
  }
}

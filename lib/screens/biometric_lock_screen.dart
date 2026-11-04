import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/features/auth/login_screen.dart';
import 'package:chopel_app/screens/main_layout_screen.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';

class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  bool _isAuthenticating = false;
  bool _isUnlocked = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _statusMessage = null;
    });

    final authenticated = await AuthService().authenticateWithBiometrics();

    if (!mounted) return;

    if (authenticated) {
      setState(() {
        _isAuthenticating = false;
        _isUnlocked = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
          );
        }
      });
    } else {
      setState(() {
        _isAuthenticating = false;
        _statusMessage = 'הזיהוי לא הושלם. נסה שוב או היכנס באמצעות סיסמה.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isUnlocked,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Icon(
                  LucideIcons.fingerprint,
                  size: 96,
                  color: AppTheme.successGreen,
                ),
                const SizedBox(height: AppTheme.spacing32),
                Text(
                  'אבטחה ביומטרית',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing16),
                Text(
                  'המערכת מכילה מידע רפואי רגיש.\nאמת את זהותך באמצעות טביעת אצבע או זיהוי פנים.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing32),
                if (_statusMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacing16),
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        color: AppTheme.warningAmber,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const Spacer(),
                HopalButton(
                  label: 'אימות ביומטרי',
                  icon: LucideIcons.fingerprint,
                  isLoading: _isAuthenticating,
                  isExpanded: true,
                  onPressed: _authenticate,
                ),
                const SizedBox(height: AppTheme.spacing12),
                TextButton(
                  onPressed: () async {
                    await AuthService().logout();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  child: Text(
                    'כניסה באמצעות סיסמה',
                    style: TextStyle(color: AppTheme.textSecondary),
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

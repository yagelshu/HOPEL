import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/screens/main_layout_screen.dart';

class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;
  String _authorized = 'לא מאומת';

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
        _authorized = 'מבצע זיהוי...';
      });
      authenticated = await auth.authenticate(
        localizedReason: 'אנא אשר את זהותך כדי לגשת למידע הרפואי',
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );
      setState(() {
        _isAuthenticating = false;
      });
    } on PlatformException catch (e) {
      print(e);
      setState(() {
        _isAuthenticating = false;
        _authorized = 'שגיאה בזיהוי';
      });
      return;
    }
    
    if (!mounted) return;

    if (authenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
      );
    } else {
      setState(() {
        _authorized = 'הזיהוי נכשל, נסה שנית';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                size: 100,
                color: AppTheme.primaryGreen,
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
                'המערכת מכילה מידע רפואי רגיש.\nנא אמת את זהותך כדי להמשיך.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing48),
              if (_authorized != 'לא מאומת' && _authorized != 'מבצע זיהוי...')
                Text(
                  _authorized,
                  style: TextStyle(
                    color: AppTheme.warningAmber,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              const Spacer(),
              HopalButton(
                label: 'נסה שוב',
                icon: LucideIcons.refreshCcw,
                isLoading: _isAuthenticating,
                isExpanded: true,
                onPressed: _authenticate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

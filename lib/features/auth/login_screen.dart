import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_text_field.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/core/network/sync_engine.dart';
import 'package:chopel_app/features/dashboard/dashboard_screen.dart';
import 'package:chopel_app/screens/main_layout_screen.dart';
import 'package:chopel_app/features/onboarding/deployment_selection_screen.dart';
import 'package:chopel_app/features/onboarding/unit_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // For registration
  
  bool _isLoading = false;
  bool _isRegistering = false;
  bool _hasStoredCredentials = false;

  @override
  void initState() {
    super.initState();
    _checkStoredCredentials();
  }

  Future<void> _checkStoredCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasStoredCredentials = prefs.containsKey('saved_email') && prefs.containsKey('saved_password');
    });
  }

  Future<void> _loginWithBiometrics() async {
    final success = await AuthService().authenticateWithBiometrics();
    if (success) {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('saved_email');
      final password = prefs.getString('saved_password');
      if (email != null && password != null) {
        _emailController.text = email;
        _passwordController.text = password;
        await _submit();
      }
    }
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    if (email.isEmpty || password.isEmpty) {
      HopalFeedback.showError(context, 'נא להזין אימייל וסיסמה');
      return;
    }

    setState(() => _isLoading = true);

    String? error;
    if (_isRegistering) {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        HopalFeedback.showError(context, 'נא להזין שם מלא');
        setState(() => _isLoading = false);
        return;
      }
      error = await AuthService().register(email, password, name);
    } else {
      error = await AuthService().login(email, password);
    }

    if (!mounted) return;
    
    setState(() => _isLoading = false);

    if (error == null) {
      // Sync basic data from cloud on fresh login
      await SyncEngine().fetchFromCloud('units');
      await SyncEngine().fetchFromCloud('soldiers');
      await SyncEngine().fetchFromCloud('medical_cases');
      
      if (!mounted) return;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_email', email);
      await prefs.setString('saved_password', password);

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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
        );
      }
    } else {
      HopalFeedback.showError(context, error);
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final resetEmailController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundSecondary,
        title: Text('איפוס סיסמה', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('הזן את כתובת האימייל שלך ונשלח לך קישור לאיפוס הסיסמה.', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: AppTheme.spacing16),
            HopalTextField(
              controller: resetEmailController,
              hint: 'אימייל',
              icon: LucideIcons.mail,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ביטול', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              if (resetEmailController.text.trim().isEmpty) return;
              Navigator.pop(context);
              final error = await AuthService().resetPassword(resetEmailController.text.trim());
              if (context.mounted) {
                if (error == null) {
                  HopalFeedback.showSuccess(context, 'קישור לאיפוס סיסמה נשלח למייל בהצלחה');
                } else {
                  HopalFeedback.showError(context, 'שגיאה בשליחת אימייל השחזור');
                }
              }
            },
            child: Text('שלח אימייל', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.spacing48),
              Center(
                child: ClipRRect(
                  borderRadius: AppTheme.radiusLg,
                  child: Transform.scale(
                    scale: 1.05, // Zoom in slightly to hide any white edge pixels
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),
              Text(
                'חופ״ל - מערכת רפואה מבצעית',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing48),
              
              if (_isRegistering) ...[
                HopalTextField(
                  controller: _nameController,
                  hint: 'שם מלא',
                  icon: LucideIcons.user,
                ),
                const SizedBox(height: AppTheme.spacing16),
              ],
              
              HopalTextField(
                controller: _emailController,
                hint: 'אימייל',
                icon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppTheme.spacing16),
              
              HopalTextField(
                controller: _passwordController,
                hint: 'סיסמה (לפחות 6 תווים)',
                icon: LucideIcons.lock,
                obscureText: true,
              ),
              if (!_isRegistering)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => _showForgotPasswordDialog(context),
                    child: Text('שכחת סיסמה?', style: TextStyle(color: AppTheme.infoBlue)),
                  ),
                ),
              const SizedBox(height: AppTheme.spacing24),
              
              HopalButton(
                label: _isRegistering ? 'צור חשבון חדש' : 'כניסה למערכת',
                onPressed: _submit,
                isLoading: _isLoading,
                icon: _isRegistering ? LucideIcons.userPlus : LucideIcons.logIn,
                isExpanded: true,
              ),
              if (!_isRegistering && _hasStoredCredentials) ...[
                const SizedBox(height: AppTheme.spacing16),
                HopalButton(
                  label: 'התחברות מהירה (ביומטרי)',
                  onPressed: _loginWithBiometrics,
                  variant: HopalButtonVariant.secondary,
                  icon: LucideIcons.fingerprint,
                  isExpanded: true,
                ),
              ],
              const SizedBox(height: AppTheme.spacing24),
              
              TextButton(
                onPressed: () {
                  setState(() => _isRegistering = !_isRegistering);
                },
                child: Text(
                  _isRegistering ? 'כבר יש לך חשבון? התחבר' : 'אין לך חשבון? הירשם כאן',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

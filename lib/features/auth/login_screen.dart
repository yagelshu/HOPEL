import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_text_field.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/core/network/sync_engine.dart';
import 'package:chopel_app/screens/main_layout_screen.dart';
import 'package:chopel_app/features/onboarding/deployment_selection_screen.dart';
import 'package:chopel_app/features/onboarding/unit_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  final bool isSessionLock;

  const LoginScreen({super.key, this.isSessionLock = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // For registration

  bool _isLoading = false;
  bool _isBiometricLoading = false;
  bool _isRegistering = false;
  bool _canSignInWithBiometrics = false;
  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
    _checkStoredCredentials();
    final pendingError = AuthService().pendingAuthErrorMessage;
    if (pendingError != null) {
      AuthService().pendingAuthErrorMessage = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          HopalFeedback.showError(context, pendingError);
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _checkStoredCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail =
        prefs.getString('saved_email') ?? Supabase.instance.client.auth.currentUser?.email;
    final useBiometrics = prefs.getBool('use_biometrics') ?? false;
    final hasSavedPassword =
        prefs.containsKey('saved_email') && prefs.containsKey('saved_password');

    if (!mounted) return;
    setState(() {
      _canSignInWithBiometrics =
          useBiometrics && (AuthService().isAuthenticated || hasSavedPassword);
      if (savedEmail != null && _emailController.text.isEmpty) {
        _emailController.text = savedEmail;
      }
    });
  }

  void _routeAfterAuthenticated() {
    if (!mounted) return;
    setState(() => _isUnlocked = true);

    if (widget.isSessionLock && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

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
  }

  Future<void> _loginWithBiometrics() async {
    setState(() => _isBiometricLoading = true);
    final success = await AuthService().authenticateWithBiometrics();
    if (!mounted) return;
    setState(() => _isBiometricLoading = false);

    if (success) {
      // Fast unlock when an authenticated session is already present
      if (AuthService().isAuthenticated) {
        if (AuthService().currentUser == null) {
          await AuthService().loadProfile();
        }
        _routeAfterAuthenticated();
        return;
      }

      // Otherwise sign in using stored credentials
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('saved_email');
      final password = prefs.getString('saved_password');
      if (email != null && password != null) {
        _emailController.text = email;
        _passwordController.text = password;
        await _submit();
      } else if (mounted) {
        HopalFeedback.showInfo(
          context,
          'לאחר התנתקות מלאה יש להזין סיסמה פעם אחת לשמירת החיבור המהיר.',
        );
      }
    } else if (mounted) {
      HopalFeedback.showError(
        context,
        'הזיהוי הביומטרי לא הושלם. נסה שוב או הזן את הסיסמה בשדה למטה.',
      );
    }
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      HopalFeedback.showError(context, 'נא להזין אימייל וסיסמה');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      HopalFeedback.showError(context, 'נא להזין כתובת אימייל תקינה');
      return;
    }

    if (_isRegistering && password.length < 6) {
      HopalFeedback.showError(context, 'הסיסמה חייבת להכיל לפחות 6 תווים');
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

      _routeAfterAuthenticated();
    } else {
      if (_isRegistering && error.contains('כבר קיים במערכת')) {
        setState(() => _isRegistering = false);
        HopalFeedback.showInfo(
          context,
          'משתמש עם אימייל זה כבר קיים במערכת – העברנו אותך למסך ההתחברות.',
        );
      } else {
        HopalFeedback.showError(context, error);
      }
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('ביטול', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final resetEmail = resetEmailController.text.trim();
              if (resetEmail.isEmpty || !resetEmail.contains('@') || !resetEmail.contains('.')) {
                HopalFeedback.showError(this.context, 'נא להזין כתובת אימייל תקינה');
                return;
              }
              Navigator.pop(dialogContext);
              final error = await AuthService().resetPassword(resetEmail);
              if (mounted) {
                if (error == null) {
                  HopalFeedback.showSuccess(this.context, 'קישור לאיפוס סיסמה נשלח למייל! בדוק את תיבת הדואר (וגם ספאם).');
                } else {
                  HopalFeedback.showError(this.context, error);
                }
              }
            },
            child: Text('שלח אימייל', style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isSessionLock || _isUnlocked,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppTheme.spacing40),
                Center(
                  child: ClipRRect(
                    borderRadius: AppTheme.radiusLg,
                    child: Transform.scale(
                      scale: 1.05, // Zoom in slightly to hide any white edge pixels
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        width: 112,
                        height: 112,
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
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  _isRegistering
                      ? 'פתיחת חשבון חדש במערכת'
                      : (_canSignInWithBiometrics
                          ? 'התחבר באמצעות טביעת אצבע או הזן סיסמה'
                          : 'התחברות לסביבת הפלוגה'),
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing32),

                if (!_isRegistering && _canSignInWithBiometrics) ...[
                  HopalButton(
                    label: 'כניסה מהירה בטביעת אצבע / זיהוי פנים',
                    onPressed: _loginWithBiometrics,
                    isLoading: _isBiometricLoading,
                    icon: LucideIcons.fingerprint,
                    isExpanded: true,
                  ),
                  const SizedBox(height: AppTheme.spacing24),
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppTheme.borderSubtle)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12),
                        child: Text(
                          'או כניסה באמצעות סיסמה',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ),
                      Expanded(child: Divider(color: AppTheme.borderSubtle)),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing24),
                ],

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
                const SizedBox(height: AppTheme.spacing16),

                HopalButton(
                  label: _isRegistering ? 'צור חשבון חדש' : 'כניסה עם סיסמה',
                  onPressed: _submit,
                  isLoading: _isLoading,
                  variant: (!_isRegistering && _canSignInWithBiometrics)
                      ? HopalButtonVariant.secondary
                      : HopalButtonVariant.primary,
                  icon: _isRegistering ? LucideIcons.userPlus : LucideIcons.logIn,
                  isExpanded: true,
                ),
                const SizedBox(height: AppTheme.spacing24),

                if (widget.isSessionLock)
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
                      'התנתק / החלף משתמש',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                else
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
      ),
    );
  }
}

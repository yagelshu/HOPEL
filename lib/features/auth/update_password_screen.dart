import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/screens/splash_screen.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_text_field.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _updatePassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.length < 6) {
      HopalFeedback.showError(context, 'הסיסמה חייבת להכיל לפחות 6 תווים');
      return;
    }

    if (password != confirmPassword) {
      HopalFeedback.showError(context, 'הסיסמאות אינן תואמות');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      AuthService().isPasswordRecovery = false;

      final currentEmail = Supabase.instance.client.auth.currentUser?.email;
      if (currentEmail != null) {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getString('saved_email') == currentEmail) {
          await prefs.setString('saved_password', password);
        }
      }

      if (mounted) {
        HopalFeedback.showSuccess(context, 'הסיסמה עודכנה בהצלחה!');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        HopalFeedback.showError(context, AuthService.localizeAuthError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text('עדכון סיסמה', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'הזן את הסיסמה החדשה שלך למטה.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing32),
              HopalTextField(
                controller: _passwordController,
                hint: 'סיסמה חדשה (לפחות 6 תווים)',
                icon: LucideIcons.lock,
                obscureText: true,
              ),
              const SizedBox(height: AppTheme.spacing16),
              HopalTextField(
                controller: _confirmPasswordController,
                hint: 'אימות סיסמה חדשה',
                icon: LucideIcons.lock,
                obscureText: true,
              ),
              const SizedBox(height: AppTheme.spacing32),
              HopalButton(
                label: 'עדכן סיסמה',
                onPressed: _updatePassword,
                isLoading: _isLoading,
                icon: LucideIcons.checkCircle,
                isExpanded: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

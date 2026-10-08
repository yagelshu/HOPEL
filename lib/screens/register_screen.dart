import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';
import 'package:chopel_app/theme/components/hopal_text_field.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _unitController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8, vertical: AppTheme.spacing12),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(LucideIcons.arrowRight, color: AppTheme.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
                child: Column(
                  children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundSecondary,
                  borderRadius: AppTheme.radiusLg,
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                  image: const DecorationImage(
                    image: AssetImage('assets/icon/app_icon.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),
              Text(
                'הקמת פרופיל חופ"ל',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, letterSpacing: -0.5),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 40, height: 1, color: AppTheme.primaryGreen),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
                    child: Text('רישום סגל רפואי', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                  Container(width: 40, height: 1, color: AppTheme.primaryGreen),
                ],
              ),
              const SizedBox(height: AppTheme.spacing40),
              HopalCard(
                padding: const EdgeInsets.all(AppTheme.spacing24),
                child: Column(
                  children: [
                    HopalTextField(
                      controller: _idController,
                      hint: 'מספר אישי',
                      icon: LucideIcons.hash,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    HopalTextField(
                      controller: _nameController,
                      hint: 'שם מלא ודרגה',
                      icon: LucideIcons.user,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    HopalTextField(
                      controller: _unitController,
                      hint: "שיוך יחידתי (גדוד / פלוגה)",
                      icon: LucideIcons.shield,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    HopalTextField(
                      controller: _passwordController,
                      hint: 'סיסמה מאובטחת',
                      icon: LucideIcons.lock,
                      isPassword: true,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    HopalTextField(
                      controller: _pinController,
                      hint: 'קוד גישה מהיר (4 ספרות)',
                      icon: LucideIcons.key,
                      keyboardType: TextInputType.number,
                      isPassword: true,
                    ),
                    const SizedBox(height: AppTheme.spacing32),
                    HopalButton(
                      label: 'צור פרופיל מבצעי',
                      icon: LucideIcons.shieldCheck,
                      isExpanded: true,
                      onPressed: () {
                        Navigator.pop(context); // Demo navigation
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

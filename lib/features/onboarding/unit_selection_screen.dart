import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_text_field.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:chopel_app/core/network/unit_service.dart';
import 'package:chopel_app/features/onboarding/deployment_selection_screen.dart';
import 'package:chopel_app/features/auth/login_screen.dart';
import 'package:chopel_app/core/auth/auth_service.dart';

class UnitSelectionScreen extends StatefulWidget {
  const UnitSelectionScreen({super.key});

  @override
  State<UnitSelectionScreen> createState() => _UnitSelectionScreenState();
}

class _UnitSelectionScreenState extends State<UnitSelectionScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  
  bool _isLoading = false;
  bool _isCreating = true;

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    try {
      bool success = false;
      if (_isCreating) {
        final name = _nameController.text.trim();
        if (name.isEmpty) {
          HopalFeedback.showError(context, 'נא להזין שם לפלוגה');
          setState(() => _isLoading = false);
          return;
        }
        success = await UnitService().createUnit(name);
      } else {
        final code = _codeController.text.trim();
        if (code.isEmpty || code.length != 6) {
          HopalFeedback.showError(context, 'נא להזין קוד בן 6 תווים');
          setState(() => _isLoading = false);
          return;
        }
        success = await UnitService().joinUnit(code);
      }

      if (!mounted) return;
      
      setState(() => _isLoading = false);

      if (success) {
        await AuthService().loadProfile();
        // After unit is set, go to deployment selection
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DeploymentSelectionScreen()),
        );
      } else {
        HopalFeedback.showError(context, _isCreating ? 'שגיאה ביצירת הפלוגה' : 'קוד ההצטרפות אינו תקין');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      HopalFeedback.showError(context, e.toString());
    }
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
              Icon(LucideIcons.users, size: 80, color: AppTheme.primaryGreen),
              const SizedBox(height: AppTheme.spacing24),
              Text(
                'סביבת הפלוגה שלך',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                _isCreating 
                    ? 'צור סביבה חדשה עבור הפלוגה שלך. תוכל בהמשך להזמין חובשים נוספים.'
                    : 'הזן את קוד ההצטרפות שקיבלת מהחופ"ל שלך.',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing48),
              
              if (_isCreating) ...[
                HopalTextField(
                  controller: _nameController,
                  hint: 'שם הפלוגה (לדוגמה: פלוגה ג\')',
                  icon: LucideIcons.flag,
                ),
              ] else ...[
                HopalTextField(
                  controller: _codeController,
                  hint: 'קוד הצטרפות (6 תווים)',
                  icon: LucideIcons.key,
                ),
              ],
              
              const SizedBox(height: AppTheme.spacing32),
              
              HopalButton(
                label: _isCreating ? 'צור פלוגה חדשה' : 'הצטרף לפלוגה',
                onPressed: _submit,
                isLoading: _isLoading,
                icon: _isCreating ? LucideIcons.plusCircle : LucideIcons.logIn,
                isExpanded: true,
              ),
              const SizedBox(height: AppTheme.spacing24),
              
              TextButton(
                onPressed: () {
                  setState(() => _isCreating = !_isCreating);
                },
                child: Text(
                  _isCreating ? 'יש לך קוד? הצטרף לפלוגה קיימת' : 'רוצה ליצור פלוגה חדשה במקום?',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              TextButton(
                onPressed: () async {
                  await AuthService().logout();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text('התנתק והחלף משתמש', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

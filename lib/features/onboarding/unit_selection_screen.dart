import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_segmented_control.dart';
import 'package:chopel_app/theme/components/hopal_text_field.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:chopel_app/core/network/unit_service.dart';
import 'package:chopel_app/core/utils/platoon_helper.dart';
import 'package:chopel_app/features/onboarding/deployment_selection_screen.dart';
import 'package:chopel_app/features/auth/login_screen.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/core/utils/app_error_helper.dart';
import 'package:chopel_app/screens/main_layout_screen.dart';
import 'package:chopel_app/features/dashboard/providers.dart';
import 'package:chopel_app/features/equipment/providers.dart';
import 'package:chopel_app/features/medical_cases/providers.dart';

class UnitSelectionScreen extends ConsumerStatefulWidget {
  const UnitSelectionScreen({super.key});

  @override
  ConsumerState<UnitSelectionScreen> createState() => _UnitSelectionScreenState();
}

class _UnitSelectionScreenState extends ConsumerState<UnitSelectionScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _platoonController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isCreating = false; // Default to joining with code so combat medics never accidentally create a new company!

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _platoonController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

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
        final code = _codeController.text.trim().replaceAll(RegExp(r'\s+'), '');
        if (code.isEmpty || code.length != 6) {
          HopalFeedback.showError(context, 'נא להזין קוד הצטרפות בן 6 תווים');
          setState(() => _isLoading = false);
          return;
        }
        final normalizedPlatoon = _platoonController.text.trim().isNotEmpty
            ? PlatoonHelper.normalize(_platoonController.text.trim())
            : null;
        success = await UnitService().joinUnit(
          code,
          platoon: normalizedPlatoon,
          phoneNumber: _phoneController.text.trim(),
        );
      }

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        await AuthService().loadProfile();
        ref.invalidate(equipmentProvider);
        ref.invalidate(medicalCasesProvider);
        ref.invalidate(soldiersProvider);
        ref.invalidate(dashboardMetricsProvider);

        if (!mounted) return;
        final hasActiveDeployment = AuthService().currentUser?.activeDeploymentId != null;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => hasActiveDeployment
                ? const MainLayoutScreen()
                : const DeploymentSelectionScreen(),
          ),
        );
      } else {
        HopalFeedback.showError(
          context,
          _isCreating ? 'שגיאה ביצירת הפלוגה' : 'קוד ההצטרפות אינו תקין – בדוק מול החופ"ל שלך',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      HopalFeedback.showError(
        context,
        AppErrorHelper.toHebrew(e, fallback: 'שגיאה בהגדרת הפלוגה. נסה שוב.'),
      );
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
              const SizedBox(height: AppTheme.spacing24),
              Icon(LucideIcons.users, size: 68, color: AppTheme.primaryGreen),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                'חיבור לסביבת הפלוגה',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                _isCreating
                    ? 'הקמת סביבת פלוגה חדשה לחופ"ל. לאחר ההקמה תקבל קוד בן 6 תווים להזמנת חובשי המחלקות שלך.'
                    : 'לחובשי הפלוגה: הזן את קוד ההצטרפות שקיבלת מהחופ"ל ובחר את המחלקה שלך.',
                style: TextStyle(fontSize: 15, color: AppTheme.textSecondary, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing24),
              HopalSegmentedControl(
                segments: const ['יש לי קוד (חובש)', 'פתיחת פלוגה (חופ"ל)'],
                selectedIndex: _isCreating ? 1 : 0,
                onValueChanged: (idx) {
                  setState(() => _isCreating = idx == 1);
                },
              ),
              const SizedBox(height: AppTheme.spacing24),
              if (_isCreating) ...[
                HopalTextField(
                  controller: _nameController,
                  hint: 'שם הפלוגה (לדוגמה: פלוגה ב\' / פלוגת מסלול)',
                  icon: LucideIcons.flag,
                ),
              ] else ...[
                HopalTextField(
                  controller: _codeController,
                  hint: 'קוד הצטרפות פלוגתי (6 תווים)',
                  icon: LucideIcons.key,
                ),
                const SizedBox(height: AppTheme.spacing16),
                HopalTextField(
                  controller: _platoonController,
                  hint: 'המחלקה שלך (לדוגמה: מחלקה 1 / מפלג)',
                  icon: LucideIcons.shield,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: PlatoonHelper.quickSelectPlatoons.map((plt) {
                    return ActionChip(
                      label: Text(plt, style: const TextStyle(fontSize: 11)),
                      backgroundColor: AppTheme.backgroundTertiary,
                      onPressed: () {
                        setState(() => _platoonController.text = plt);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppTheme.spacing16),
                HopalTextField(
                  controller: _phoneController,
                  hint: 'מספר טלפון אישי (אופציונלי – לחיוג מהיר בצוות)',
                  icon: LucideIcons.phone,
                  keyboardType: TextInputType.phone,
                ),
              ],
              const SizedBox(height: AppTheme.spacing32),
              HopalButton(
                label: _isCreating ? 'צור סביבת פלוגה חדשה' : 'הצטרף לפלוגה עכשיו',
                onPressed: _submit,
                isLoading: _isLoading,
                icon: _isCreating ? LucideIcons.plusCircle : LucideIcons.logIn,
                isExpanded: true,
              ),
              const SizedBox(height: AppTheme.spacing16),
              TextButton(
                onPressed: () {
                  setState(() => _isCreating = !_isCreating);
                },
                child: Text(
                  _isCreating ? 'יש לך קוד? הצטרף לפלוגה קיימת' : 'אתה חופ"ל של פלוגה חדשה? לחץ להקמת פלוגה',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              TextButton(
                onPressed: () async {
                  await AuthService().logout();
                  if (!context.mounted) return;
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

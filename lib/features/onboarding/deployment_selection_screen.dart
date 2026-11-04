import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_text_field.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/core/utils/app_error_helper.dart';
import 'package:chopel_app/screens/main_layout_screen.dart';
import 'package:chopel_app/features/auth/login_screen.dart';
import 'package:chopel_app/features/onboarding/unit_selection_screen.dart';
import 'package:chopel_app/features/dashboard/providers.dart';
import 'package:chopel_app/features/medical_cases/providers.dart';
import 'package:chopel_app/features/equipment/providers.dart';

class DeploymentSelectionScreen extends ConsumerStatefulWidget {
  const DeploymentSelectionScreen({super.key});

  @override
  ConsumerState<DeploymentSelectionScreen> createState() => _DeploymentSelectionScreenState();
}

class _DeploymentSelectionScreenState extends ConsumerState<DeploymentSelectionScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createNewDeployment() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      HopalFeedback.showError(context, 'נא להזין שם לתעסוקה');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = AuthService().currentUser;
      if (user == null) throw Exception('User not found');

      if (user.unitId != null) {
        try {
          await Supabase.instance.client
              .from('deployments')
              .update({
                'is_active': false,
                'end_date': DateTime.now().toIso8601String(),
              })
              .eq('unit_id', user.unitId!)
              .eq('is_active', true);
        } catch (_) {}
      }

      final deploymentId = const Uuid().v4();
      final payload = {
        'id': deploymentId,
        'name': name,
        'start_date': DateTime.now().toIso8601String(),
        'end_date': null,
        'unit_id': user.unitId,
        'is_active': true,
      };

      // 1. Create deployment in Supabase
      await Supabase.instance.client.from('deployments').insert(payload);

      // 2. Assign deployment to user
      await Supabase.instance.client.from('users').update({
        'active_deployment_id': deploymentId,
      }).eq('id', user.id);

      // Update current user optimistically
      AuthService().updateCurrentUserDeployment(deploymentId, name);
      ref.invalidate(dashboardMetricsProvider);
      ref.invalidate(medicalCasesProvider);
      ref.invalidate(equipmentProvider);

      if (!mounted) return;

      HopalFeedback.showSuccess(context, 'תעסוקה $name נוצרה בהצלחה!');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
      );
    } catch (e) {
      if (mounted) {
        HopalFeedback.showError(
          context,
          AppErrorHelper.toHebrew(e, fallback: 'שגיאה ביצירת תעסוקה'),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _switchUnit() async {
    try {
      await AuthService().detachFromCurrentUnit();
      ref.invalidate(medicalCasesProvider);
      ref.invalidate(soldiersProvider);
      ref.invalidate(equipmentProvider);
      ref.invalidate(dashboardMetricsProvider);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const UnitSelectionScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        HopalFeedback.showError(
          context,
          AppErrorHelper.toHebrew(e, fallback: 'שגיאה במעבר פלוגה'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unitName = AuthService().currentUser?.unitName;

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.spacing48),
              Icon(LucideIcons.tent, size: 80, color: AppTheme.primaryGreen),
              const SizedBox(height: AppTheme.spacing24),
              Text(
                'פתיחת תעסוקה חדשה',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                textAlign: TextAlign.center,
              ),
              if (unitName != null && unitName.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  unitName,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.militaryOlive),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'תן שם לתעסוקה הנוכחית (לדוגמה: קו חברון, אימון רמת הגולן) כדי שכל הפניות הרפואיות ישויכו אליה.',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing48),
              HopalTextField(
                controller: _nameController,
                hint: 'שם התעסוקה...',
                icon: LucideIcons.mapPin,
              ),
              const SizedBox(height: AppTheme.spacing32),
              HopalButton(
                label: 'פתיחת תעסוקה ויציאה לדרך',
                onPressed: _createNewDeployment,
                isLoading: _isLoading,
                icon: LucideIcons.flag,
                isExpanded: true,
              ),
              const SizedBox(height: AppTheme.spacing24),
              TextButton(
                onPressed: _isLoading ? null : _switchUnit,
                child: Text(
                  'החלפת פלוגה / יצירת פלוגה חדשה',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
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

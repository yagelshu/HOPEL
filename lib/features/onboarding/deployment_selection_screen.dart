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
import 'package:chopel_app/core/network/sync_engine.dart';
import 'package:chopel_app/features/dashboard/dashboard_screen.dart';
import 'package:chopel_app/screens/main_layout_screen.dart';
import 'package:chopel_app/features/auth/login_screen.dart';

class DeploymentSelectionScreen extends ConsumerStatefulWidget {
  const DeploymentSelectionScreen({super.key});

  @override
  ConsumerState<DeploymentSelectionScreen> createState() => _DeploymentSelectionScreenState();
}

class _DeploymentSelectionScreenState extends ConsumerState<DeploymentSelectionScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

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

      final deploymentId = const Uuid().v4();
      final payload = {
        'id': deploymentId,
        'name': name,
        'start_date': DateTime.now().toIso8601String(),
        'end_date': null,
        'unit_id': user.unitId,
        'is_active': 1, // true in SQLite
      };

      // 1. Create deployment in Supabase
      payload['is_active'] = true; // Supabase expects boolean usually, but if it expects int, we should keep it int. Wait, SQLite was 1, Supabase is boolean.
      // Let's ensure the payload conforms to Supabase boolean for is_active.
      payload['is_active'] = true;

      await Supabase.instance.client.from('deployments').insert(payload);

      // 2. Assign deployment to user
      await Supabase.instance.client.from('users').update({
        'active_deployment_id': deploymentId,
      }).eq('id', user.id);
      
      // Update current user optimistically
      AuthService().updateCurrentUserDeployment(deploymentId, name);

      if (!mounted) return;
      
      HopalFeedback.showSuccess(context, 'תעסוקה $name נוצרה בהצלחה!');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
      );
    } catch (e) {
      if (mounted) HopalFeedback.showError(context, 'שגיאה ביצירת תעסוקה');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(LucideIcons.tent, size: 80, color: AppTheme.primaryGreen),
              const SizedBox(height: AppTheme.spacing24),
              Text(
                'פתיחת תעסוקה חדשה',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'לא מוגדרת לך תעסוקה כרגע.\nתן שם לתעסוקה החדשה (לדוגמה: קו חברון, אימון רמת הגולן) כדי שכל הפניות הרפואיות ישויכו אליה.',
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

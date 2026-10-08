import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_text_field.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:chopel_app/models/soldier.dart';
import 'package:chopel_app/features/medical_cases/providers.dart';

class SoldiersManagementScreen extends ConsumerStatefulWidget {
  const SoldiersManagementScreen({super.key});

  @override
  ConsumerState<SoldiersManagementScreen> createState() => _SoldiersManagementScreenState();
}

class _SoldiersManagementScreenState extends ConsumerState<SoldiersManagementScreen> {
  void _showAddSoldierDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundSecondary,
        title: Text('הוספת חייל', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HopalTextField(
              controller: nameController,
              hint: 'שם מלא (לדוגמה: ישראל ישראלי (1234567))',
              icon: LucideIcons.user,
            ),
            const SizedBox(height: AppTheme.spacing16),
            HopalTextField(
              controller: phoneController,
              hint: 'טלפון (אופציונלי)',
              icon: LucideIcons.phone,
              keyboardType: TextInputType.phone,
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
              if (nameController.text.trim().isEmpty) {
                HopalFeedback.showError(context, 'שם החייל לא יכול להיות ריק');
                return;
              }

              try {
                final user = Supabase.instance.client.auth.currentUser;
                final userData = await Supabase.instance.client.from('users').select('unit_id').eq('id', user!.id).single();
                
                await Supabase.instance.client.from('soldiers').insert({
                  'name': nameController.text.trim(),
                  'phone_number': phoneController.text.trim(),
                  'unit_id': userData['unit_id'],
                });
                
                if (context.mounted) {
                  ref.invalidate(soldiersProvider);
                  Navigator.pop(context);
                  HopalFeedback.showSuccess(context, 'החייל התווסף בהצלחה');
                }
              } catch (e) {
                if (context.mounted) {
                  HopalFeedback.showError(context, 'שגיאה בהוספת החייל: $e');
                }
              }
            },
            child: Text('הוסף', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditSoldierDialog(Soldier soldier) {
    final nameController = TextEditingController(text: soldier.name);
    final phoneController = TextEditingController(text: soldier.phoneNumber ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundSecondary,
        title: Text('עריכת חייל', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HopalTextField(
              controller: nameController,
              hint: 'שם מלא (לדוגמה: ישראל ישראלי (1234567))',
              icon: LucideIcons.user,
            ),
            const SizedBox(height: AppTheme.spacing16),
            HopalTextField(
              controller: phoneController,
              hint: 'טלפון (אופציונלי)',
              icon: LucideIcons.phone,
              keyboardType: TextInputType.phone,
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
              if (nameController.text.trim().isEmpty) {
                HopalFeedback.showError(context, 'שם החייל לא יכול להיות ריק');
                return;
              }

              try {
                await Supabase.instance.client
                    .from('soldiers')
                    .update({
                      'name': nameController.text.trim(),
                      'phone_number': phoneController.text.trim(),
                    })
                    .eq('id', soldier.id);
                
                if (context.mounted) {
                  ref.invalidate(soldiersProvider);
                  Navigator.pop(context);
                  HopalFeedback.showSuccess(context, 'פרטי החייל עודכנו בהצלחה');
                }
              } catch (e) {
                if (context.mounted) {
                  HopalFeedback.showError(context, 'שגיאה בעדכון החייל: $e');
                }
              }
            },
            child: Text('שמור שינויים', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSoldier(Soldier soldier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundSecondary,
        title: Text('מחיקת חייל', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'האם אתה בטוח שברצונך למחוק את החייל ${soldier.name}? כל התיקים הרפואיים שלו יימחקו גם כן. הפעולה אינה הפיכה.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ביטול', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('מחק חייל', style: TextStyle(color: AppTheme.criticalRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('soldiers').delete().eq('id', soldier.id);
        if (mounted) {
          ref.invalidate(soldiersProvider);
          HopalFeedback.showSuccess(context, 'החייל נמחק בהצלחה');
        }
      } catch (e) {
        if (mounted) HopalFeedback.showError(context, 'שגיאה במחיקת החייל: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final soldiersAsync = ref.watch(soldiersProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text('ניהול חיילים', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowRight, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: soldiersAsync.when(
        data: (soldiers) {
          if (soldiers.isEmpty) {
            return Center(
              child: Text('לא נמצאו חיילים בפלוגה', style: TextStyle(color: AppTheme.textSecondary)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            itemCount: soldiers.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final soldier = soldiers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                  child: Icon(LucideIcons.user, color: AppTheme.primaryGreen),
                ),
                title: Text(soldier.name, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                subtitle: Text(soldier.phoneNumber ?? 'ללא מספר טלפון', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(LucideIcons.edit2, color: AppTheme.infoBlue, size: 20),
                      onPressed: () => _showEditSoldierDialog(soldier),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.trash2, color: AppTheme.criticalRed, size: 20),
                      onPressed: () => _deleteSoldier(soldier),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (err, stack) => Center(child: Text('שגיאה: $err', style: TextStyle(color: AppTheme.criticalRed))),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSoldierDialog,
        backgroundColor: AppTheme.primaryGreen,
        child: Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }
}

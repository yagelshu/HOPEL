import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_text_field.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/models/soldier.dart';
import 'package:chopel_app/features/medical_cases/providers.dart';
import 'package:chopel_app/features/profile/soldiers_import_screen.dart';

class SoldiersManagementScreen extends ConsumerStatefulWidget {
  const SoldiersManagementScreen({super.key});

  @override
  ConsumerState<SoldiersManagementScreen> createState() => _SoldiersManagementScreenState();
}

class _SoldiersManagementScreenState extends ConsumerState<SoldiersManagementScreen> {
  String _query = '';

  /// Add (soldier == null) or edit.
  void _showSoldierDialog([Soldier? soldier]) {
    final nameController = TextEditingController(text: soldier?.name ?? '');
    final pnController = TextEditingController(text: soldier?.personalNumber ?? '');
    final phoneController = TextEditingController(text: soldier?.phoneNumber ?? '');
    final platoonController = TextEditingController(text: soldier?.platoon ?? '');
    final isEdit = soldier != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundSecondary,
        title: Text(isEdit ? 'עריכת חייל' : 'הוספת חייל',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HopalTextField(controller: nameController, hint: 'שם מלא', icon: LucideIcons.user),
              const SizedBox(height: AppTheme.spacing16),
              HopalTextField(
                controller: pnController,
                hint: 'מספר אישי',
                icon: LucideIcons.hash,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppTheme.spacing16),
              HopalTextField(
                controller: phoneController,
                hint: 'טלפון (אופציונלי)',
                icon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppTheme.spacing16),
              HopalTextField(controller: platoonController, hint: 'מחלקה (אופציונלי)', icon: LucideIcons.users),
            ],
          ),
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
              String? orNull(String v) => v.trim().isEmpty ? null : v.trim();
              final data = {
                'name': nameController.text.trim(),
                'personal_number': orNull(pnController.text.replaceAll(RegExp(r'\D'), '')),
                'phone_number': orNull(phoneController.text),
                'platoon': orNull(platoonController.text),
              };
              try {
                final client = Supabase.instance.client;
                if (isEdit) {
                  await client.from('soldiers').update(data).eq('id', soldier.id);
                } else {
                  final unitId = AuthService().currentUser?.unitId;
                  if (unitId == null) throw Exception('לא נמצאה פלוגה למשתמש');
                  await client.from('soldiers').insert({...data, 'unit_id': unitId});
                }
                if (context.mounted) {
                  ref.invalidate(soldiersProvider);
                  Navigator.pop(context);
                  HopalFeedback.showSuccess(context, isEdit ? 'פרטי החייל עודכנו' : 'החייל נוסף בהצלחה');
                }
              } on PostgrestException catch (e) {
                if (context.mounted) {
                  final msg = e.code == '23505' ? 'כבר קיים חייל עם המספר האישי הזה' : e.message;
                  HopalFeedback.showError(context, 'שגיאה: $msg');
                }
              } catch (e) {
                if (context.mounted) HopalFeedback.showError(context, 'שגיאה: $e');
              }
            },
            child: Text(isEdit ? 'שמור שינויים' : 'הוסף',
                style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
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

  void _openImport() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SoldiersImportScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final soldiersAsync = ref.watch(soldiersProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text('ניהול חיילים',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowRight, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            key: const Key('soldiers_import_button'),
            tooltip: 'ייבוא מאקסל',
            icon: Icon(LucideIcons.fileSpreadsheet, color: AppTheme.primaryGreen),
            onPressed: _openImport,
          ),
        ],
      ),
      body: soldiersAsync.when(
        data: (all) {
          final q = _query.trim().toLowerCase();
          final soldiers = q.isEmpty
              ? [...all]
              : all.where((s) => s.displayLabel.toLowerCase().contains(q)).toList();
          soldiers.sort((a, b) => a.name.compareTo(b.name));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, AppTheme.spacing8, AppTheme.spacing16, 0),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'חיפוש לפי שם או מספר אישי (${all.length} חיילים)',
                    prefixIcon: Icon(LucideIcons.search, color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.backgroundSecondary,
                    border: OutlineInputBorder(borderRadius: AppTheme.radiusMd, borderSide: BorderSide.none),
                  ),
                ),
              ),
              Expanded(
                child: all.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, AppTheme.spacing8, AppTheme.spacing16, 96),
                        itemCount: soldiers.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final soldier = soldiers[index];
                          final details = [
                            if (soldier.personalNumber != null) 'מ.א ${soldier.personalNumber}',
                            if (soldier.phoneNumber != null && soldier.phoneNumber!.isNotEmpty) soldier.phoneNumber!,
                            if (soldier.platoon != null && soldier.platoon!.isNotEmpty) 'מחלקה ${soldier.platoon}',
                          ].join(' • ');
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                              child: Icon(LucideIcons.user, color: AppTheme.primaryGreen),
                            ),
                            title: Text(soldier.name,
                                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                            subtitle: Text(details.isEmpty ? 'אין פרטים נוספים' : details,
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(LucideIcons.edit2, color: AppTheme.infoBlue, size: 20),
                                  onPressed: () => _showSoldierDialog(soldier),
                                ),
                                IconButton(
                                  icon: Icon(LucideIcons.trash2, color: AppTheme.criticalRed, size: 20),
                                  onPressed: () => _deleteSoldier(soldier),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: Text('שגיאה: $err', style: TextStyle(color: AppTheme.criticalRed)),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('soldiers_add_button'),
        onPressed: () => _showSoldierDialog(),
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.users, size: 56, color: AppTheme.textSecondary),
            const SizedBox(height: AppTheme.spacing16),
            Text('עדיין אין חיילים בפלוגה', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
            const SizedBox(height: AppTheme.spacing8),
            Text('הכי מהיר: ייבוא רשימה מאקסל', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: AppTheme.spacing16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              onPressed: _openImport,
              icon: const Icon(LucideIcons.fileSpreadsheet, color: Colors.white),
              label: const Text('ייבוא מאקסל', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

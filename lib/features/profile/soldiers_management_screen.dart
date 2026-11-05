import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';
import 'package:chopel_app/theme/components/hopal_text_field.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:chopel_app/core/utils/app_error_helper.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/models/soldier.dart';
import 'package:chopel_app/features/medical_cases/medical_case_create_screen.dart';
import 'package:chopel_app/features/medical_cases/providers.dart';
import 'package:chopel_app/features/profile/soldiers_import_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SoldiersManagementScreen extends ConsumerStatefulWidget {
  final bool isEmbeddedTab;

  const SoldiersManagementScreen({super.key, this.isEmbeddedTab = false});

  @override
  ConsumerState<SoldiersManagementScreen> createState() => _SoldiersManagementScreenState();
}

class _SoldiersManagementScreenState extends ConsumerState<SoldiersManagementScreen> {
  String _query = '';
  String _selectedPlatoon = 'הכל';
  bool _onlyAllergies = false;

  /// Add (soldier == null) or edit.
  void _showSoldierDialog([Soldier? soldier]) {
    final nameController = TextEditingController(text: soldier?.name ?? '');
    final pnController = TextEditingController(text: soldier?.personalNumber ?? '');
    final phoneController = TextEditingController(text: soldier?.phoneNumber ?? '');
    final platoonController = TextEditingController(text: soldier?.platoon ?? '');
    final allergiesController = TextEditingController(text: soldier?.allergies ?? '');
    final isEdit = soldier != null;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.backgroundSecondary,
        title: Text(
          isEdit ? 'עריכת פרטי חייל' : 'הוספת חייל חדש',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
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
              const SizedBox(height: AppTheme.spacing16),
              HopalTextField(
                controller: allergiesController,
                hint: 'אלרגיות / רגישויות (G6PD, פניצילין וכו\')',
                icon: LucideIcons.alertTriangle,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: ['G6PD', 'פניצילין', 'אופטלגין', 'NSAID'].map((alg) {
                  return ActionChip(
                    label: Text(alg, style: const TextStyle(fontSize: 11)),
                    backgroundColor: AppTheme.backgroundTertiary,
                    onPressed: () {
                      final current = allergiesController.text.trim();
                      allergiesController.text = current.isEmpty ? alg : '$current, $alg';
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          if (isEdit)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteSoldier(soldier);
              },
              child: Text('מחק חייל', style: TextStyle(color: AppTheme.criticalRed)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('ביטול', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                HopalFeedback.showError(context, 'שם החייל לא יכול להיות ריק');
                return;
              }
              String? orNull(String v) => v.trim().isEmpty ? null : v.trim();
              final rawName = nameController.text.trim();
              final rawPn = orNull(pnController.text.replaceAll(RegExp(r'\D'), ''));
              final rawAllergies = orNull(allergiesController.text);
              final data = <String, dynamic>{
                'name': rawName,
                'personal_number': rawPn,
                'phone_number': orNull(phoneController.text),
                'platoon': orNull(platoonController.text),
                'allergies': rawAllergies,
              };
              try {
                final client = Supabase.instance.client;
                if (isEdit) {
                  try {
                    await client.from('soldiers').update(data).eq('id', soldier.id);
                  } on PostgrestException catch (pe) {
                    if (pe.code == 'PGRST204' || pe.code == '42703' || pe.message.contains('allergies') || pe.message.contains('personal_number')) {
                      final fallbackData = <String, dynamic>{
                        'name': rawPn != null && rawPn.isNotEmpty ? '$rawName ($rawPn)' : rawName,
                        'phone_number': orNull(phoneController.text),
                        'platoon': orNull(platoonController.text),
                      };
                      await client.from('soldiers').update(fallbackData).eq('id', soldier.id);
                    } else {
                      rethrow;
                    }
                  }
                } else {
                  final unitId = AuthService().currentUser?.unitId;
                  if (unitId == null) throw Exception('לא נמצאה פלוגה למשתמש');
                  try {
                    await client.from('soldiers').insert({...data, 'unit_id': unitId});
                  } on PostgrestException catch (pe) {
                    if (pe.code == 'PGRST204' || pe.code == '42703' || pe.message.contains('allergies') || pe.message.contains('personal_number')) {
                      final fallbackData = <String, dynamic>{
                        'name': rawPn != null && rawPn.isNotEmpty ? '$rawName ($rawPn)' : rawName,
                        'phone_number': orNull(phoneController.text),
                        'platoon': orNull(platoonController.text),
                        'unit_id': unitId,
                      };
                      await client.from('soldiers').insert(fallbackData);
                    } else {
                      rethrow;
                    }
                  }
                }
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (mounted) {
                  ref.invalidate(soldiersProvider);
                  HopalFeedback.showSuccess(this.context, isEdit ? 'פרטי החייל עודכנו' : 'החייל נוסף בהצלחה');
                }
              } on PostgrestException catch (e) {
                if (mounted) {
                  HopalFeedback.showError(this.context, AppErrorHelper.toHebrew(e, fallback: 'שגיאה בשמירת פרטי החייל.'));
                }
              } catch (e) {
                if (mounted) {
                  HopalFeedback.showError(this.context, AppErrorHelper.toHebrew(e, fallback: 'שגיאה בשמירת פרטי החייל.'));
                }
              }
            },
            child: Text(
              isEdit ? 'שמור שינויים' : 'הוסף',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
        if (mounted) HopalFeedback.showError(context, AppErrorHelper.toHebrew(e, fallback: 'שגיאה במחיקת החייל. נסה שוב.'));
      }
    }
  }

  void _openImport() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SoldiersImportScreen()));
  }

  void _openMedicalCaseForSoldier(Soldier soldier) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicalCaseCreateScreen(initialSoldierId: soldier.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final soldiersAsync = ref.watch(soldiersProvider);

    return ValueListenableBuilder<bool>(
      valueListenable: AuthService().previewAsCombatMedicNotifier,
      builder: (context, _, __) {
        final isCompanyMedic = AuthService().isCompanyMedic;

        return Scaffold(
          backgroundColor: AppTheme.backgroundPrimary,
          appBar: AppBar(
            automaticallyImplyLeading: !widget.isEmbeddedTab,
            title: Column(
              crossAxisAlignment: widget.isEmbeddedTab ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                Text(
                  'חיילי הפלוגה',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 19),
                ),
                soldiersAsync.maybeWhen(
                  data: (list) => Text(
                    '${list.length} חיילים במצבת',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            backgroundColor: AppTheme.backgroundPrimary,
            elevation: 0,
            centerTitle: !widget.isEmbeddedTab,
            leading: widget.isEmbeddedTab
                ? null
                : IconButton(
                    icon: Icon(LucideIcons.arrowRight, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
            actions: [
              if (isCompanyMedic)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12, vertical: 8),
                  child: TextButton.icon(
                    key: const Key('soldiers_import_button'),
                    onPressed: _openImport,
                    icon: Icon(LucideIcons.fileSpreadsheet, color: AppTheme.primaryGreen, size: 17),
                    label: Text(
                      'ייבוא מאקסל',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.radiusPill,
                        side: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.35)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: soldiersAsync.when(
            data: (all) {
              final platoons = <String>['הכל'];
              for (final s in all) {
                if (s.platoon != null && s.platoon!.trim().isNotEmpty && !platoons.contains(s.platoon!.trim())) {
                  platoons.add(s.platoon!.trim());
                }
              }
              final hasAnyAllergies = all.any((s) => s.hasAllergies);

              final q = _query.trim().toLowerCase();
              final cleanQ = q.replaceAll(RegExp(r'[\s-]'), '');
              final soldiers = all.where((s) {
                final cleanPn = (s.personalNumber ?? '').replaceAll(RegExp(r'[\s-]'), '').toLowerCase();
                final matchesQuery = q.isEmpty ||
                    s.name.toLowerCase().contains(q) ||
                    (cleanPn.isNotEmpty && cleanPn.contains(cleanQ)) ||
                    (s.phoneNumber != null && s.phoneNumber!.contains(cleanQ)) ||
                    (s.platoon != null && s.platoon!.toLowerCase().contains(q)) ||
                    (s.allergies != null && s.allergies!.toLowerCase().contains(q));

                final matchesPlatoon = _selectedPlatoon == 'הכל' || s.platoon?.trim() == _selectedPlatoon;
                final matchesAllergy = !_onlyAllergies || s.hasAllergies;
                return matchesQuery && matchesPlatoon && matchesAllergy;
              }).toList();
              soldiers.sort((a, b) => a.name.compareTo(b.name));

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, AppTheme.spacing8, AppTheme.spacing16, 0),
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      style: TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'חיפוש לפי שם, מ.א, מחלקה, טלפון או רגישות...',
                        prefixIcon: Icon(LucideIcons.search, color: AppTheme.textSecondary),
                        filled: true,
                        fillColor: AppTheme.backgroundSecondary,
                        border: OutlineInputBorder(borderRadius: AppTheme.radiusMd, borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  if (platoons.length > 1 || hasAnyAllergies)
                    Container(
                      height: 48,
                      margin: const EdgeInsets.only(top: 8),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                        children: [
                          if (hasAnyAllergies) ...[
                            FilterChip(
                              avatar: Icon(
                                LucideIcons.alertTriangle,
                                size: 14,
                                color: _onlyAllergies ? AppTheme.criticalRed : AppTheme.textSecondary,
                              ),
                              label: const Text('בעלי רגישות'),
                              selected: _onlyAllergies,
                              onSelected: (v) => setState(() => _onlyAllergies = v),
                              selectedColor: AppTheme.criticalRed.withValues(alpha: 0.18),
                              backgroundColor: AppTheme.backgroundSecondary,
                              labelStyle: TextStyle(
                                color: _onlyAllergies ? AppTheme.criticalRed : AppTheme.textSecondary,
                                fontWeight: _onlyAllergies ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          ...platoons.map((p) {
                            final isSelected = _selectedPlatoon == p;
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ChoiceChip(
                                label: Text(p),
                                selected: isSelected,
                                onSelected: (_) => setState(() => _selectedPlatoon = p),
                                selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                                backgroundColor: AppTheme.backgroundSecondary,
                                labelStyle: TextStyle(
                                  color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppTheme.primaryGreen,
                      onRefresh: () async {
                        ref.invalidate(soldiersProvider);
                        await ref.read(soldiersProvider.future);
                      },
                      child: all.isEmpty
                          ? _buildEmpty(isCompanyMedic)
                          : soldiers.isEmpty
                              ? Center(
                                  child: Text(
                                    'לא נמצאו חיילים תואמים לחיפוש',
                                    style: TextStyle(color: AppTheme.textSecondary),
                                  ),
                                )
                              : ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: EdgeInsets.fromLTRB(
                                    AppTheme.spacing16,
                                    AppTheme.spacing12,
                                    AppTheme.spacing16,
                                    widget.isEmbeddedTab ? 140 : 96,
                                  ),
                                  itemCount: soldiers.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacing8),
                                  itemBuilder: (context, index) {
                                    final soldier = soldiers[index];
                                    final hasPhone = soldier.phoneNumber != null && soldier.phoneNumber!.trim().isNotEmpty;
                                    final details = [
                                      if (soldier.personalNumber != null) 'מ.א ${soldier.personalNumber}',
                                      if (soldier.platoon != null && soldier.platoon!.isNotEmpty) 'מחלקה ${soldier.platoon}',
                                      if (hasPhone) soldier.phoneNumber!,
                                    ].join(' • ');

                                    return HopalCard(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      borderColor: soldier.hasAllergies
                                          ? AppTheme.criticalRed.withValues(alpha: 0.4)
                                          : AppTheme.borderSubtle,
                                      onTap: isCompanyMedic
                                          ? () => _showSoldierDialog(soldier)
                                          : () => _openMedicalCaseForSoldier(soldier),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: soldier.hasAllergies
                                                ? AppTheme.criticalRed.withValues(alpha: 0.15)
                                                : AppTheme.primaryGreen.withValues(alpha: 0.12),
                                            child: Icon(
                                              soldier.hasAllergies ? LucideIcons.alertTriangle : LucideIcons.user,
                                              size: 18,
                                              color: soldier.hasAllergies ? AppTheme.criticalRed : AppTheme.primaryGreen,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 4,
                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                  children: [
                                                    Text(
                                                      soldier.name,
                                                      style: TextStyle(
                                                        color: AppTheme.textPrimary,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                    if (soldier.hasAllergies)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: AppTheme.criticalRed.withValues(alpha: 0.15),
                                                          borderRadius: BorderRadius.circular(4),
                                                          border: Border.all(color: AppTheme.criticalRed.withValues(alpha: 0.45)),
                                                        ),
                                                        child: Text(
                                                          'רגישות: ${soldier.allergies}',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: AppTheme.criticalRed,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  details.isEmpty ? 'ללא פרטים נוספים' : details,
                                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(LucideIcons.filePlus2, color: AppTheme.primaryGreen, size: 18),
                                                tooltip: 'פתיחת פנייה רפואית',
                                                visualDensity: VisualDensity.compact,
                                                onPressed: () => _openMedicalCaseForSoldier(soldier),
                                              ),
                                              if (hasPhone) ...[
                                                IconButton(
                                                  icon: Icon(LucideIcons.phone, color: AppTheme.primaryGreen, size: 17),
                                                  tooltip: 'חיוג לחייל',
                                                  visualDensity: VisualDensity.compact,
                                                  onPressed: () async {
                                                    final uri = Uri.parse('tel:${soldier.phoneNumber!.replaceAll(RegExp(r'\D'), '')}');
                                                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                                                  },
                                                ),
                                                IconButton(
                                                  icon: Icon(LucideIcons.messageCircle, color: AppTheme.successGreen, size: 17),
                                                  tooltip: 'שלח WhatsApp',
                                                  visualDensity: VisualDensity.compact,
                                                  onPressed: () async {
                                                    var phone = soldier.phoneNumber!.replaceAll(RegExp(r'\D'), '');
                                                    if (phone.startsWith('0')) phone = '972${phone.substring(1)}';
                                                    final uri = Uri.parse('https://wa.me/$phone');
                                                    if (await canLaunchUrl(uri)) {
                                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                    }
                                                  },
                                                ),
                                              ],
                                              if (isCompanyMedic)
                                                IconButton(
                                                  icon: Icon(LucideIcons.pencil, color: AppTheme.infoBlue, size: 17),
                                                  tooltip: 'ערוך פרטי חייל',
                                                  visualDensity: VisualDensity.compact,
                                                  onPressed: () => _showSoldierDialog(soldier),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ),
                ],
              );
            },
            loading: () => Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing24),
                child: Text(
                  AppErrorHelper.toHebrew(err, fallback: 'שגיאה בטעינת רשימת החיילים.'),
                  style: TextStyle(color: AppTheme.criticalRed),
                ),
              ),
            ),
          ),
          floatingActionButton: isCompanyMedic
              ? Padding(
                  padding: EdgeInsets.only(bottom: widget.isEmbeddedTab ? 110.0 : 12.0),
                  child: FloatingActionButton.extended(
                    key: const Key('soldiers_add_button'),
                    onPressed: () => _showSoldierDialog(),
                    backgroundColor: AppTheme.primaryGreen,
                    icon: const Icon(LucideIcons.userPlus, color: Colors.white, size: 18),
                    label: const Text(
                      'הוסף חייל',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildEmpty(bool isCompanyMedic) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spacing24),
      children: [
        const SizedBox(height: 60),
        Icon(LucideIcons.users, size: 56, color: AppTheme.textSecondary),
        const SizedBox(height: AppTheme.spacing16),
        Text(
          'עדיין אין חיילים רשומים בפלוגה',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          isCompanyMedic
              ? 'ייבא בלחיצה אחת קובץ אקסל (‎.xlsx / ‎.csv) של הפלוגה או הוסף חיילים ידנית. ניתן לערוך כל פרט בכל רגע.'
              : 'החופ"ל יכול לייבא את מצבת החיילים מקובץ אקסל כדי שיופיעו כאן.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, height: 1.45),
        ),
        if (isCompanyMedic) ...[
          const SizedBox(height: AppTheme.spacing24),
          HopalButton(
            label: 'ייבוא רשימת פלוגה מאקסל (.xlsx / .csv)',
            icon: LucideIcons.fileSpreadsheet,
            onPressed: _openImport,
          ),
          const SizedBox(height: AppTheme.spacing12),
          HopalButton(
            label: 'הוספת חייל בודד ידנית',
            icon: LucideIcons.userPlus,
            variant: HopalButtonVariant.secondary,
            onPressed: () => _showSoldierDialog(),
          ),
        ],
      ],
    );
  }
}

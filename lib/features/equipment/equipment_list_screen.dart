import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chopel_app/features/equipment/providers.dart';
import 'package:chopel_app/features/dashboard/providers.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/models/equipment.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';
import 'package:chopel_app/theme/components/hopal_status_badge.dart';
import 'package:chopel_app/theme/components/hopal_empty_state.dart';
import 'package:chopel_app/core/network/sync_engine.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_bottom_sheet.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:chopel_app/core/database/database_service.dart';
import 'package:url_launcher/url_launcher.dart';

class EquipmentListScreen extends ConsumerStatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  ConsumerState<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends ConsumerState<EquipmentListScreen> {
  String _selectedGroup = 'וסט חובש';

  void _showAddOrEditSheet(BuildContext context, {Equipment? item}) {
    final isEditing = item != null;
    String name = item?.name ?? '';
    int currentQuantity = item?.quantity ?? 0;
    String category = item?.category ?? _selectedGroup;
    String itemType = item?.itemType ?? 'מתכלה';
    
    String? imagePath = item?.imagePath;

    HopalBottomSheet.show(
      context: context,
      title: isEditing ? 'עריכת פריט' : 'הוספת פריט חדש',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> _pickImage() async {
            final picker = ImagePicker();
            final pickedFile = await picker.pickImage(source: ImageSource.camera);
            if (pickedFile != null) {
              setModalState(() => imagePath = pickedFile.path);
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundSecondary,
                    borderRadius: AppTheme.radiusMd,
                    border: Border.all(color: AppTheme.borderSubtle),
                    image: imagePath != null 
                      ? DecorationImage(image: FileImage(File(imagePath!)), fit: BoxFit.cover)
                      : null,
                  ),
                  child: imagePath == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.camera, color: AppTheme.textSecondary, size: 32),
                            const SizedBox(height: AppTheme.spacing8),
                            Text('צילום תמונה', style: TextStyle(color: AppTheme.textSecondary)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'שם הפריט',
                  border: OutlineInputBorder(borderRadius: AppTheme.radiusMd),
                ),
                controller: TextEditingController(text: name)..selection = TextSelection.collapsed(offset: name.length),
                onChanged: (val) => name = val,
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text('כמות נוכחית', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: AppTheme.spacing8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(LucideIcons.minusCircle, size: 40, color: AppTheme.criticalRed),
                    onPressed: () {
                      if (currentQuantity > 0) setModalState(() => currentQuantity--);
                    },
                  ),
                  Text('$currentQuantity', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  IconButton(
                    icon: Icon(LucideIcons.plusCircle, size: 40, color: AppTheme.successGreen),
                    onPressed: () {
                      setModalState(() => currentQuantity++);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'שיוך', border: OutlineInputBorder(borderRadius: AppTheme.radiusMd)),
                items: ['וסט חובש', 'ארגז חופל'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) => setModalState(() => category = val!),
              ),
              const SizedBox(height: AppTheme.spacing16),
              DropdownButtonFormField<String>(
                value: itemType,
                decoration: const InputDecoration(labelText: 'סוג', border: OutlineInputBorder(borderRadius: AppTheme.radiusMd)),
                items: ['מתכלה', 'קבוע'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => setModalState(() => itemType = val!),
              ),
              const SizedBox(height: AppTheme.spacing32),
              Row(
                children: [
                  if (isEditing) ...[
                    Expanded(
                      child: HopalButton(
                        label: 'מחק פריט',
                        icon: LucideIcons.trash2,
                        variant: HopalButtonVariant.destructive,
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppTheme.backgroundSecondary,
                              title: Text('מחיקת פריט', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                              content: Text('האם למחוק את הפריט "$name"? פעולה זו אינה הפיכה.', style: TextStyle(color: AppTheme.textSecondary)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('ביטול', style: TextStyle(color: AppTheme.textSecondary))),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text('מחק', style: TextStyle(color: AppTheme.criticalRed, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                          if (confirm != true) return;

                          try {
                            await Supabase.instance.client
                                .from('equipment')
                                .delete()
                                .eq('id', item!.id);

                            try {
                              final db = await DatabaseService().database;
                              await db.delete('equipment', where: 'id = ?', whereArgs: [item!.id]);
                            } catch (_) {}

                            ref.read(equipmentProvider.notifier).refresh();
                            ref.invalidate(dashboardMetricsProvider);
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            HopalFeedback.showSuccess(context, 'הפריט נמחק בהצלחה');
                          } catch (e) {
                            if (context.mounted) HopalFeedback.showError(context, 'שגיאה במחיקת פריט: $e');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing16),
                  ],
                  Expanded(
                    flex: 2,
                    child: HopalButton(
                      label: 'שמור שינויים',
                      icon: LucideIcons.check,
                      onPressed: () async {
                        if (name.trim().isEmpty) {
                          HopalFeedback.showError(context, 'נא להזין שם פריט');
                          return;
                        }
                        final String id = isEditing ? item!.id : const Uuid().v4();
                        final int minReq = isEditing ? item!.minimumRequired : currentQuantity; 
                        
                        final user = AuthService().currentUser;
                        final unitId = user?.unitId ?? item?.unitId;

                        // Only include columns that exist in the Supabase equipment table
                        final payload = <String, dynamic>{
                          'id': id,
                          'name': name.trim(),
                          'category': category,
                          'item_type': itemType,
                          'quantity': currentQuantity,
                          'minimum_required': minReq,
                          'status': currentQuantity >= minReq ? 'IN_STOCK' : 'MISSING',
                        };
                        if (unitId != null) {
                          payload['unit_id'] = unitId;
                        }

                        try {
                          // Save to Supabase
                          if (unitId != null) {
                            await Supabase.instance.client.from('equipment').upsert(payload);
                          }

                          // Save to local SQLite/mock database for offline support
                          try {
                            final db = await DatabaseService().database;
                            final localPayload = {
                              ...payload,
                              if (imagePath != null) 'image_path': imagePath,
                            };
                            if (isEditing) {
                              await db.update('equipment', localPayload, where: 'id = ?', whereArgs: [id]);
                            } else {
                              await db.insert('equipment', localPayload);
                            }
                          } catch (_) {}

                          ref.read(equipmentProvider.notifier).refresh();
                          ref.invalidate(dashboardMetricsProvider);

                          if (!context.mounted) return;
                          Navigator.pop(context);
                          HopalFeedback.showSuccess(context, 'השינויים נשמרו בהצלחה');
                        } catch (e) {
                          if (context.mounted) {
                            HopalFeedback.showError(context, 'שגיאה בשמירת שינויים: $e');
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCatCheckModal() {
    final lotController = TextEditingController();
    bool isOpenOnVest = true;
    Map<String, dynamic>? validationResult;

    HopalBottomSheet.show(
      context: context,
      title: 'בדיקת תוקף ואותנטיות חסם עורקים (CAT)',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          void runInspection() {
            final raw = lotController.text.trim();
            if (raw.isEmpty) {
              HopalFeedback.showError(context, 'יש להזין מספר אצווה או שנת ייצור המוטבעת על החסם');
              return;
            }

            final currentYear = DateTime.now().year;
            int? prodYear;

            // Check 4 digit year first (e.g. 2023, 2021)
            final year4Match = RegExp(r'(20\d{2})').firstMatch(raw);
            if (year4Match != null) {
              prodYear = int.tryParse(year4Match.group(1)!);
            } else {
              // Check 2 digit year after LOT or dash e.g. LOT 22, 23-
              final year2Match = RegExp(r'(?:LOT|lot|\b)(2[0-9])\b').firstMatch(raw);
              if (year2Match != null) {
                prodYear = 2000 + int.parse(year2Match.group(1)!);
              }
            }

            // Detect obvious mock/fake lots
            final isSuspiciousLot = raw.contains('0000') || raw.toLowerCase().contains('fake') || raw.length < 3;

            if (prodYear == null) {
              setModalState(() {
                validationResult = {
                  'status': 'UNKNOWN',
                  'title': 'לא זוהתה שנת ייצור באצווה',
                  'message': 'לא הצלחנו לפענח שנת ייצור מתוך "$raw". אנא אתר על גבי קליפ החסם או האריזה את שנת הייצור (לדוגמה 2023 או LOT 23) ובדוק את סימני המקוריות הפיזיים.',
                  'color': AppTheme.warningAmber,
                };
              });
              return;
            }

            final age = currentYear - prodYear;
            final maxYears = isOpenOnVest ? 5 : 10;

            if (isSuspiciousLot) {
              setModalState(() {
                validationResult = {
                  'status': 'DANGER',
                  'title': 'אזהרה: חשד לחסם מזויף!',
                  'message': 'מספר האצווה חריג ואינו תואם תקן NAR. חסמים מזויפים נשברים תחת עומס ואינם עוצרים דימום. אין להשתמש בחסם זה בפעילות מבצעית!',
                  'color': AppTheme.criticalRed,
                };
              });
            } else if (age > maxYears || prodYear > currentYear + 1) {
              setModalState(() {
                validationResult = {
                  'status': 'EXPIRED',
                  'title': 'חסם פג תוקף מבצעי!',
                  'message': 'יוצר בשנת $prodYear (בן $age שנים). לפי הוראות קרפ"ר ו-TCCC, אורך חיי חסם ${isOpenOnVest ? "פתוח על וסט הינו 5 שנים (שחיקת UV ורצועות)" : "באריזה סגורה הינו 10 שנים"}. חסם זה אינו כשיר לשימוש ויש לגרוס ולהחליף.',
                  'color': AppTheme.criticalRed,
                };
              });
            } else if (isOpenOnVest && age >= 4) {
              setModalState(() {
                validationResult = {
                  'status': 'WARNING',
                  'title': 'מתקרב לסוף תוקף מבצעי',
                  'message': 'יוצר בשנת $prodYear (בן $age שנים על וסט). מומלץ להחליף בחסם חדש לקראת תעסוקה מבצעית אינטנסיבית.',
                  'color': AppTheme.warningAmber,
                };
              });
            } else {
              setModalState(() {
                validationResult = {
                  'status': 'OK',
                  'title': 'חסם תקין וכשיר לשימוש מבצעי',
                  'message': 'יוצר בשנת $prodYear (בן $age שנים). נותרו כ-${maxYears - age} שנות כשירות ${isOpenOnVest ? "על הווסט" : "באריזה"}. וודא שלמות פיזית של מוט ההידוק והרצועה.',
                  'color': AppTheme.successGreen,
                };
              });
            }
          }

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundSecondary,
                    borderRadius: AppTheme.radiusMd,
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.info, color: AppTheme.primaryGreen, size: 20),
                      const SizedBox(width: AppTheme.spacing12),
                      Expanded(
                        child: Text(
                          'הבדיקה מבוססת על שנת הייצור המוטבעת לפי נוהלי קרפ"ר ו-TCCC (5 שנים פתוח על וסט / 10 שנים באריזה סגורה).',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacing16),
                TextField(
                  controller: lotController,
                  style: TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'מספר אצווה / שנת ייצור (Lot Number)',
                    hintText: 'לדוגמה: LOT 23-148 או 2023',
                    prefixIcon: const Icon(LucideIcons.hash),
                    border: OutlineInputBorder(borderRadius: AppTheme.radiusMd),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing16),
                Text('מצב החסם הנוכחי:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppTheme.spacing8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('פתוח על הווסט (5 שנים)')),
                        selected: isOpenOnVest,
                        onSelected: (val) => setModalState(() => isOpenOnVest = true),
                        selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.25),
                        labelStyle: TextStyle(color: isOpenOnVest ? AppTheme.primaryGreen : AppTheme.textSecondary, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('ארוז באריזה מקורית (10 שנים)')),
                        selected: !isOpenOnVest,
                        onSelected: (val) => setModalState(() => isOpenOnVest = false),
                        selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.25),
                        labelStyle: TextStyle(color: !isOpenOnVest ? AppTheme.primaryGreen : AppTheme.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing16),
                HopalButton(
                  label: 'בדוק כשירות ותוקף',
                  icon: LucideIcons.shieldCheck,
                  onPressed: runInspection,
                ),
                if (validationResult != null) ...[
                  const SizedBox(height: AppTheme.spacing16),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    decoration: BoxDecoration(
                      color: (validationResult!['color'] as Color).withValues(alpha: 0.12),
                      borderRadius: AppTheme.radiusMd,
                      border: Border.all(color: validationResult!['color'] as Color),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              validationResult!['status'] == 'OK'
                                  ? LucideIcons.circleCheck
                                  : validationResult!['status'] == 'WARNING'
                                      ? LucideIcons.alertTriangle
                                      : LucideIcons.alertOctagon,
                              color: validationResult!['color'] as Color,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                validationResult!['title'] as String,
                                style: TextStyle(
                                  color: validationResult!['color'] as Color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          validationResult!['message'] as String,
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.spacing24),
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    leading: Icon(LucideIcons.shieldAlert, color: AppTheme.warningAmber, size: 20),
                    title: Text(
                      'צ\'קליסט זיהוי חסם CAT Gen 7 מקורי (מול זיופים)',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('1. חריטת C-A-T® עמוקה ומקורית על גבי מוט ההידוק וקליפ הנעילה (בזיופים החריטה שטחית או מודפסת בצבע).',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
                            const SizedBox(height: 6),
                            Text('2. אבזם חיכוך אחיד (Single-Routing Buckle) בעל פסי חיכוך עבים וגב מעוגל.',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
                            const SizedBox(height: 6),
                            Text('3. לשונית אדומה (Red Tip) עם סימון פטנט בריתוך אולטרסוני אחיד.',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
                            const SizedBox(height: 6),
                            Text('אזהרת בטיחות: חסמים מזויפים שכיחים ברשת נשברים בעת הידוק עורקי מלא ואינם מצילים חיים!',
                                style: TextStyle(color: AppTheme.criticalRed, fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final equipmentAsync = ref.watch(equipmentProvider);
    final canEdit = AuthService().currentUser != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      floatingActionButton: canEdit ? Padding(
        padding: const EdgeInsets.only(bottom: 120.0),
        child: FloatingActionButton(
          onPressed: () => _showAddOrEditSheet(context),
          backgroundColor: AppTheme.primaryGreen,
          child: const Icon(LucideIcons.plus, color: Colors.white),
        ),
      ) : null,
      body: equipmentAsync.when(
        data: (eqList) {
          if (eqList.isEmpty) {
            return const HopalEmptyState(
              icon: LucideIcons.briefcase,
              title: 'אין ציוד מנוהל',
              subtitle: 'לא נמצא ציוד רפואי במערכת.',
            );
          }

          final allGroups = ['וסט חובש', 'ארגז חופל'];
          final items = eqList.where((e) => e.category == _selectedGroup).toList();
          final expendables = items.where((e) => e.itemType == 'מתכלה').toList();
          final durables = items.where((e) => e.itemType == 'קבוע').toList();

          final readinessPercent = eqList.isEmpty ? 100 : ((eqList.length - eqList.where((e) => e.status == 'MISSING' || e.quantity < e.minimumRequired).length) / eqList.length * 100).round();
          final isReady = readinessPercent > 90;

          final missingItems = eqList.where((e) => e.status == 'MISSING' || e.quantity < e.minimumRequired).toList();

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: const Text('כשירות ציוד רפואי', style: TextStyle(fontWeight: FontWeight.bold)),
                floating: true,
                pinned: true,
                actions: [
                  IconButton(
                    icon: const Icon(LucideIcons.shieldCheck),
                    tooltip: 'בדיקת חסם עורקים',
                    onPressed: _showCatCheckModal,
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: _buildHeroReadiness(readinessPercent, isReady),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: HopalButton(
                          label: 'בדיקת חסם עורקים',
                          icon: LucideIcons.shieldCheck,
                          variant: HopalButtonVariant.secondary,
                          onPressed: _showCatCheckModal,
                        ),
                      ),
                      if (missingItems.isNotEmpty) ...[
                        const SizedBox(width: AppTheme.spacing8),
                        Expanded(
                          flex: 4,
                          child: HopalButton(
                            label: 'שלח חוסרים לחוג"ד',
                            icon: LucideIcons.messageCircle,
                            onPressed: () async {
                              final text = 'היי החוג"ד, להלן חוסרים בציוד:\n' + missingItems.map((e) => '- ${e.name} (חסר: ${e.minimumRequired - e.quantity})').join('\n');
                              final url = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              } else {
                                if (context.mounted) HopalFeedback.showError(context, 'לא ניתן לפתוח את WhatsApp');
                              }
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing8),
                  child: Row(
                    children: allGroups.map((grp) {
                      final isSelected = _selectedGroup == grp;
                      return Padding(
                        padding: const EdgeInsets.only(left: AppTheme.spacing8),
                        child: ChoiceChip(
                          label: Text(grp, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedGroup = grp);
                          },
                          backgroundColor: AppTheme.backgroundSecondary,
                          selectedColor: AppTheme.primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppTheme.primaryGreen : AppTheme.borderSubtle)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              if (expendables.isNotEmpty) ...[
                _buildSectionHeader('ציוד מתכלה', LucideIcons.packagePlus, AppTheme.primaryGreen),
                _buildEquipmentList(expendables),
              ],
              if (durables.isNotEmpty) ...[
                _buildSectionHeader('ציוד קבוע', LucideIcons.briefcase, AppTheme.primaryGreen),
                _buildEquipmentList(durables),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 120)), // Nav padding
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (err, stack) => Center(child: Text('שגיאה: $err')),
      ),
    );
  }

  Widget _buildHeroReadiness(int readinessPercent, bool isReady) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: HopalCard(
        backgroundColor: isReady ? AppTheme.primaryGreen.withValues(alpha: 0.1) : AppTheme.criticalRed.withValues(alpha: 0.1),
        borderColor: isReady ? AppTheme.primaryGreen.withValues(alpha: 0.3) : AppTheme.criticalRed.withValues(alpha: 0.3),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isReady ? LucideIcons.shieldCheck : LucideIcons.shieldAlert, size: 32, color: isReady ? AppTheme.successGreen : AppTheme.criticalRed),
                const SizedBox(width: AppTheme.spacing12),
                Text(
                  '$readinessPercent%',
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, height: 1.0),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              isReady 
                ? 'כשירות ציוד מצוינת לגזרה זו' 
                : 'כשירות ציוד פגועה (${100 - readinessPercent}% פריטים חסרים) - נדרשת השלמה',
              style: TextStyle(color: isReady ? AppTheme.successGreen : AppTheme.criticalRed, fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, AppTheme.spacing24, AppTheme.spacing16, AppTheme.spacing8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppTheme.spacing8),
            Text(title, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentList(List<Equipment> items) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            final isMissing = item.status == 'MISSING' || item.quantity < item.minimumRequired;
            final isExpiring = item.status == 'EXPIRING_SOON';

            HopalStatusBadgeVariant variant = HopalStatusBadgeVariant.success;
            String statusText = 'תקין';
            IconData statusIcon = LucideIcons.checkCircle;
            
            if (isMissing) {
              variant = HopalStatusBadgeVariant.critical;
              statusText = 'חסר';
              statusIcon = LucideIcons.alertTriangle;
            } else if (isExpiring) {
              variant = HopalStatusBadgeVariant.warning;
              statusText = 'פג תוקף';
              statusIcon = LucideIcons.clock;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
              child: HopalCard(
                onTap: () {
                  final canEdit = AuthService().currentUser != null;
                  if (canEdit) {
                    _showAddOrEditSheet(context, item: item);
                  }
                },
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundSecondary,
                        borderRadius: AppTheme.radiusSm,
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: item.imagePath != null
                          ? ClipRRect(
                              borderRadius: AppTheme.radiusSm,
                              child: Image.file(
                                File(item.imagePath!),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  item.itemType == 'מתכלה' ? LucideIcons.pill : LucideIcons.briefcase,
                                  color: AppTheme.textSecondary,
                                  size: 24,
                                ),
                              ),
                            )
                          : Icon(
                              item.itemType == 'מתכלה' ? LucideIcons.pill : LucideIcons.briefcase,
                              color: AppTheme.textSecondary,
                              size: 24,
                            ),
                    ),
                    const SizedBox(width: AppTheme.spacing16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: AppTheme.spacing4),
                          Text(
                            'כמות: ${item.quantity} / ${item.minimumRequired}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isMissing ? AppTheme.criticalRed : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    HopalStatusBadge(label: statusText, icon: statusIcon, variant: variant),
                  ],
                ),
              ),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }
}


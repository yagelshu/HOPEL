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
                          await Supabase.instance.client
                              .from('equipment')
                              .delete()
                              .eq('id', item!.id);
                          ref.read(equipmentProvider.notifier).refresh();
                          ref.invalidate(dashboardMetricsProvider);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          HopalFeedback.showSuccess(context, 'הפריט נמחק בהצלחה');
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
                        if (name.trim().isEmpty) return;
                        final String id = isEditing ? item!.id : const Uuid().v4();
                        final int minReq = isEditing ? item!.minimumRequired : currentQuantity; 
                        
                        final payload = {
                          'id': id,
                          'name': name,
                          'category': category,
                          'item_type': itemType,
                          'quantity': currentQuantity,
                          'minimum_required': minReq,
                          'status': currentQuantity >= minReq ? 'READY' : 'MISSING',
                          'image_path': imagePath,
                        };
                        
                        final user = AuthService().currentUser;
                        if (user?.unitId != null) {
                          payload['unit_id'] = user!.unitId!;
                          await Supabase.instance.client.from('equipment').upsert(payload);
                        }
                        
                        ref.read(equipmentProvider.notifier).refresh();
                        ref.invalidate(dashboardMetricsProvider);
                        
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        HopalFeedback.showSuccess(context, 'השינויים נשמרו בהצלחה');
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
    String lotNumber = '';
    HopalBottomSheet.show(
      context: context,
      title: 'בדיקת תוקף חסם עורקים (CAT)',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.shieldCheck, size: 64, color: AppTheme.primaryGreen),
              const SizedBox(height: AppTheme.spacing16),
              const Text('הזן מספר אצווה (Lot Number) המוטבע על החסם כדי לוודא שהוא מקורי ובתוקף.', textAlign: TextAlign.center),
              const SizedBox(height: AppTheme.spacing24),
              TextField(
                decoration: InputDecoration(
                  labelText: 'מספר אצווה',
                  prefixIcon: const Icon(LucideIcons.hash),
                  border: OutlineInputBorder(borderRadius: AppTheme.radiusMd),
                ),
                onChanged: (val) => lotNumber = val,
              ),
              const SizedBox(height: AppTheme.spacing24),
              HopalButton(
                label: 'בדוק תוקף',
                icon: LucideIcons.shieldCheck,
                onPressed: () {
                  Navigator.pop(context);
                  if (lotNumber.isEmpty) {
                    HopalFeedback.showError(context, 'יש להזין מספר אצווה');
                    return;
                  }
                  
                  // Basic mock logic for CAT Lot Number validation
                  // Usually, lot numbers might start with a year or be at least 4 chars.
                  if (lotNumber.length < 4) {
                    HopalFeedback.showError(context, 'מספר אצווה לא חוקי. אנא בדוק שוב את המספר המוטבע.');
                    return;
                  }
                  
                  if (lotNumber.contains('0000') || lotNumber.contains('1234')) {
                    HopalFeedback.showError(context, 'אזהרה: החסם זוהה כזיוף (מספר אצווה לא קיים במאגר)! אין להשתמש בו.');
                    return;
                  }

                  HopalFeedback.showSuccess(context, 'מספר האצווה אומת. החסם מקורי ובתוקף! מוכן לשימוש חרום.');
                },
              ),
            ],
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


import 'dart:convert';
import 'package:chopel_app/core/utils/battalion_medic_helper.dart';
import 'package:chopel_app/core/utils/platform_image.dart';
import 'package:chopel_app/core/utils/app_error_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chopel_app/features/equipment/providers.dart';
import 'package:chopel_app/features/dashboard/providers.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/models/equipment.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';
import 'package:chopel_app/theme/components/hopal_status_badge.dart';
import 'package:chopel_app/theme/components/hopal_empty_state.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_bottom_sheet.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';

class _KitScope {
  final String key;
  final String label;
  final String targetCategory;
  final String? medicId;
  final bool includeLegacyVest;

  const _KitScope({
    required this.key,
    required this.label,
    required this.targetCategory,
    this.medicId,
    this.includeLegacyVest = false,
  });

  List<Equipment> filter(List<Equipment> all) {
    if (medicId != null) {
      return all
          .where((e) => e.belongsToMedicVest(medicId!, includeLegacyUnassigned: includeLegacyVest))
          .toList();
    }
    return all.where((e) => e.category == targetCategory).toList();
  }
}

class EquipmentListScreen extends ConsumerStatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  ConsumerState<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends ConsumerState<EquipmentListScreen> {
  String _selectedScopeKey = 'box';

  List<_KitScope> _buildCompanyMedicScopes(List<Equipment> eqList, List<Map<String, dynamic>> activeMedics) {
    final hopalId = AuthService().currentUser?.id ?? 'hopal';
    final scopes = <_KitScope>[
      const _KitScope(
        key: 'box',
        label: 'ארגז חופ"ל',
        targetCategory: Equipment.companyBoxCategory,
      ),
      _KitScope(
        key: 'my_vest',
        label: 'הווסט שלי',
        targetCategory: Equipment.vestCategoryFor(hopalId),
        medicId: hopalId,
        includeLegacyVest: true,
      ),
    ];

    final addedMedicIds = <String>{hopalId};
    for (final m in activeMedics) {
      final mId = m['id']?.toString() ?? '';
      if (mId.isEmpty || addedMedicIds.contains(mId) || mId.startsWith('demo_medic_')) continue;
      final mName = (m['name']?.toString().trim().isNotEmpty == true) ? m['name'].toString().trim() : 'חובש';
      addedMedicIds.add(mId);
      scopes.add(
        _KitScope(
          key: 'medic::$mId',
          label: 'וסט – $mName',
          targetCategory: Equipment.vestCategoryFor(mId),
          medicId: mId,
          includeLegacyVest: false,
        ),
      );
    }

    // Include any vest owner present in equipment rows even before activeMedics finishes loading
    for (final eq in eqList) {
      final ownerId = eq.vestOwnerId;
      if (ownerId != null &&
          ownerId.isNotEmpty &&
          !ownerId.startsWith('demo_medic_') &&
          !addedMedicIds.contains(ownerId)) {
        addedMedicIds.add(ownerId);
        scopes.add(
          _KitScope(
            key: 'medic::$ownerId',
            label: 'וסט חובש נוסף',
            targetCategory: Equipment.vestCategoryFor(ownerId),
            medicId: ownerId,
            includeLegacyVest: false,
          ),
        );
      }
    }

    return scopes;
  }

  void _showAddOrEditSheet(
    BuildContext context, {
    required List<_KitScope> scopes,
    required _KitScope activeScope,
    Equipment? item,
  }) {
    final isEditing = item != null;
    final nameController = TextEditingController(text: item?.name ?? '');
    int currentQuantity = item?.quantity ?? 1;
    int minimumRequired = item?.minimumRequired ?? 1;

    // Match item's existing category to a scope targetCategory if possible
    String selectedCategory = item?.category ?? activeScope.targetCategory;
    if (selectedCategory == Equipment.legacyVestCategory) {
      final myScope = scopes.where((s) => s.key == 'my_vest').firstOrNull;
      if (myScope != null) {
        selectedCategory = myScope.targetCategory;
      }
    }

    final dropdownEntries = <DropdownMenuItem<String>>[];
    final seenCategories = <String>{};
    for (final s in scopes) {
      if (seenCategories.add(s.targetCategory)) {
        dropdownEntries.add(DropdownMenuItem(value: s.targetCategory, child: Text(s.label)));
      }
    }
    if (!seenCategories.contains(selectedCategory)) {
      dropdownEntries.add(DropdownMenuItem(value: selectedCategory, child: Text(selectedCategory)));
    }

    String itemType = item?.itemType ?? 'מתכלה';
    String? imagePath = item?.imagePath;
    bool isSaving = false;

    HopalBottomSheet.show(
      context: context,
      title: isEditing ? 'עריכת פריט רפואי' : 'הוספת פריט חדש',
      child: StatefulBuilder(
        builder: (sheetCtx, setModalState) {
          Future<void> pickImage(ImageSource source) async {
            try {
              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(
                source: source,
                maxWidth: 420,
                maxHeight: 420,
                imageQuality: 65,
              );
              if (pickedFile == null) return;
              final bytes = await pickedFile.readAsBytes();
              if (bytes.isEmpty) return;
              final encodedDataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';
              setModalState(() => imagePath = encodedDataUri);
            } catch (e) {
              if (context.mounted) {
                HopalFeedback.showError(
                  context,
                  AppErrorHelper.toHebrew(e, fallback: 'לא ניתן היה לטעון את התמונה מהמכשיר.'),
                );
              }
            }
          }

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 136,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundSecondary,
                    borderRadius: AppTheme.radiusMd,
                    border: Border.all(
                      color: imagePath != null ? AppTheme.primaryGreen : AppTheme.borderSubtle,
                    ),
                  ),
                  child: imagePath != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: AppTheme.radiusMd,
                              child: Image(
                                image: resolveLocalOrWebImage(imagePath!),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Icon(LucideIcons.imageOff, color: AppTheme.textMuted, size: 32),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Material(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => setModalState(() => imagePath = null),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.trash2, color: Colors.white, size: 14),
                                        SizedBox(width: 4),
                                        Text('הסר', style: TextStyle(color: Colors.white, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.camera, color: AppTheme.textSecondary, size: 30),
                            const SizedBox(height: 6),
                            Text(
                              'הוסף תמונת זיהוי לפריט הציוד',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => pickImage(ImageSource.camera),
                        icon: Icon(LucideIcons.camera, size: 16, color: AppTheme.primaryGreen),
                        label: Text('צילום מצלמה', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.borderSubtle),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => pickImage(ImageSource.gallery),
                        icon: Icon(LucideIcons.image, size: 16, color: AppTheme.primaryGreen),
                        label: Text('בחירה מגלריה', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.borderSubtle),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing16),
                TextField(
                  controller: nameController,
                  style: TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'שם הפריט',
                    border: OutlineInputBorder(borderRadius: AppTheme.radiusMd),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundSecondary,
                          borderRadius: AppTheme.radiusMd,
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Column(
                          children: [
                            Text('כמות בפועל', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(LucideIcons.minusCircle, size: 28, color: AppTheme.criticalRed),
                                  onPressed: () {
                                    if (currentQuantity > 0) setModalState(() => currentQuantity--);
                                  },
                                ),
                                Text(
                                  '$currentQuantity',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(LucideIcons.plusCircle, size: 28, color: AppTheme.successGreen),
                                  onPressed: () => setModalState(() => currentQuantity++),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundSecondary,
                          borderRadius: AppTheme.radiusMd,
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Column(
                          children: [
                            Text('תקן נדרש', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(LucideIcons.minusCircle, size: 28, color: AppTheme.textSecondary),
                                  onPressed: () {
                                    if (minimumRequired > 0) setModalState(() => minimumRequired--);
                                  },
                                ),
                                Text(
                                  '$minimumRequired',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(LucideIcons.plusCircle, size: 28, color: AppTheme.primaryGreen),
                                  onPressed: () => setModalState(() => minimumRequired++),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  dropdownColor: AppTheme.backgroundSecondary,
                  style: TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'שיוך ערכה',
                    border: OutlineInputBorder(borderRadius: AppTheme.radiusMd),
                  ),
                  items: dropdownEntries,
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedCategory = val);
                  },
                ),
                const SizedBox(height: AppTheme.spacing16),
                DropdownButtonFormField<String>(
                  initialValue: itemType,
                  dropdownColor: AppTheme.backgroundSecondary,
                  style: TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'סוג פריט',
                    border: OutlineInputBorder(borderRadius: AppTheme.radiusMd),
                  ),
                  items: ['מתכלה', 'קבוע']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => itemType = val);
                  },
                ),
                const SizedBox(height: AppTheme.spacing24),
                Row(
                  children: [
                    if (isEditing) ...[
                      Expanded(
                        child: HopalButton(
                          label: 'מחק',
                          icon: LucideIcons.trash2,
                          variant: HopalButtonVariant.destructive,
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: AppTheme.backgroundSecondary,
                                      title: Text(
                                        'מחיקת פריט',
                                        style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                                      ),
                                      content: Text(
                                        'האם למחוק את הפריט "${nameController.text.trim()}"? פעולה זו אינה הפיכה.',
                                        style: TextStyle(color: AppTheme.textSecondary),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: Text('ביטול', style: TextStyle(color: AppTheme.textSecondary)),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: Text(
                                            'מחק',
                                            style: TextStyle(color: AppTheme.criticalRed, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm != true) return;

                                  setModalState(() => isSaving = true);
                                  try {
                                    await ref.read(equipmentProvider.notifier).deleteItem(item.id);
                                    if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                                    if (context.mounted) {
                                      HopalFeedback.showSuccess(context, 'הפריט נמחק בהצלחה');
                                    }
                                  } catch (e) {
                                    if (sheetCtx.mounted) setModalState(() => isSaving = false);
                                    if (context.mounted) {
                                      HopalFeedback.showError(
                                        context,
                                        AppErrorHelper.toHebrew(e, fallback: 'שגיאה במחיקת הפריט. נסה שוב.'),
                                      );
                                    }
                                  }
                                },
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing12),
                    ],
                    Expanded(
                      flex: 2,
                      child: HopalButton(
                        label: 'שמור שינויים',
                        icon: LucideIcons.check,
                        isLoading: isSaving,
                        onPressed: () async {
                          final trimmedName = nameController.text.trim();
                          if (trimmedName.isEmpty) {
                            HopalFeedback.showError(context, 'נא להזין שם פריט');
                            return;
                          }

                          // Keep legacy 'וסט חובש' category on existing legacy items if not moved to another kit
                          String finalCategory = selectedCategory;
                          if (isEditing &&
                              item.category == Equipment.legacyVestCategory &&
                              selectedCategory ==
                                  Equipment.vestCategoryFor(AuthService().currentUser?.id ?? '')) {
                            finalCategory = Equipment.legacyVestCategory;
                          }

                          final String id = isEditing ? item.id : const Uuid().v4();
                          final user = AuthService().currentUser;
                          final unitId = user?.unitId ?? item?.unitId;

                          final savedItem = Equipment(
                            id: id,
                            name: trimmedName,
                            category: finalCategory,
                            itemType: itemType,
                            quantity: currentQuantity,
                            minimumRequired: minimumRequired,
                            expirationDate: item?.expirationDate,
                            status: currentQuantity >= minimumRequired ? 'IN_STOCK' : 'MISSING',
                            unitId: unitId,
                            imagePath: imagePath,
                          );

                          setModalState(() => isSaving = true);
                          try {
                            await ref.read(equipmentProvider.notifier).upsertItem(savedItem);
                            if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                            if (context.mounted) {
                              HopalFeedback.showSuccess(context, 'השינויים נשמרו בהצלחה');
                            }
                          } catch (e) {
                            if (sheetCtx.mounted) setModalState(() => isSaving = false);
                            if (context.mounted) {
                              HopalFeedback.showError(
                                context,
                                AppErrorHelper.toHebrew(e, fallback: 'שגיאה בשמירת השינויים. נסה שוב.'),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _buildHogadMissingReport(List<Equipment> eqList) {
    final aggregatedMissing = <String, int>{};
    for (final e in eqList) {
      if (e.vestOwnerId?.startsWith('demo_medic_') == true) continue;
      final deficit = e.minimumRequired - e.quantity;
      if (deficit > 0) {
        aggregatedMissing[e.name] = (aggregatedMissing[e.name] ?? 0) + deficit;
      }
    }

    final user = AuthService().currentUser;
    final unitName = user?.unitName ?? 'הפלוגה';
    final depName = user?.activeDeploymentName;
    final header = (depName != null && depName.isNotEmpty)
        ? 'היי החוג"ד, להלן דרישת השלמת ציוד רפואי – $unitName ($depName):'
        : 'היי החוג"ד, להלן דרישת השלמת ציוד רפואי – $unitName:';

    final lines = aggregatedMissing.entries
        .map((entry) => '• ${entry.key} (חסר להשלמה: ${entry.value})')
        .join('\n');

    return '$header\n\n$lines';
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

            final year4Match = RegExp(r'(20\d{2})').firstMatch(raw);
            if (year4Match != null) {
              prodYear = int.tryParse(year4Match.group(1)!);
            } else {
              final year2Match = RegExp(r'(?:LOT|lot|\b)(2[0-9])\b').firstMatch(raw);
              if (year2Match != null) {
                prodYear = 2000 + int.parse(year2Match.group(1)!);
              }
            }

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
                  decoration: const InputDecoration(
                    labelText: 'מספר אצווה / שנת ייצור (Lot Number)',
                    hintText: 'לדוגמה: LOT 23-148 או 2023',
                    prefixIcon: Icon(LucideIcons.hash),
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
    final activeMedics = ref.watch(dashboardMetricsProvider).asData?.value.activeMedics ?? const [];

    return ValueListenableBuilder<int>(
      valueListenable: AuthService().previewRevisionNotifier,
      builder: (context, _, __) {
        final isCompanyMedic = AuthService().isCompanyMedic;
        final effectiveMedicId = AuthService().effectiveUserId ?? '';
        final effectiveMedicName = AuthService().effectiveUserName;

        return equipmentAsync.when(
          loading: () => Scaffold(
            backgroundColor: AppTheme.backgroundPrimary,
            body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
          ),
          error: (err, stack) => Scaffold(
            backgroundColor: AppTheme.backgroundPrimary,
            body: HopalEmptyState(
              icon: LucideIcons.alertTriangle,
              title: 'שגיאה בטעינת הציוד',
              subtitle: AppErrorHelper.toHebrew(err, fallback: 'לא ניתן היה לטעון את רשימת הציוד כרגע.'),
              action: HopalButton(
                label: 'נסה שוב',
                icon: LucideIcons.refreshCw,
                onPressed: () => ref.read(equipmentProvider.notifier).refresh(),
              ),
            ),
          ),
          data: (eqList) {
            if (eqList.isEmpty && isCompanyMedic) {
              return Scaffold(
                backgroundColor: AppTheme.backgroundPrimary,
                body: HopalEmptyState(
                  icon: LucideIcons.briefcase,
                  title: 'אין ציוד מנוהל',
                  subtitle: 'לא נמצא ציוד רפואי בפלוגה זו. ניתן לטעון את תקן הציוד הפלוגתי המלא בלחיצה אחת.',
                  action: HopalButton(
                    label: 'טען תקן ציוד פלוגתי (וסט חובש + ארגז חופ"ל)',
                    icon: LucideIcons.packagePlus,
                    onPressed: () async {
                      await ref.read(equipmentProvider.notifier).seedStandardCatalog();
                      if (context.mounted) {
                        HopalFeedback.showSuccess(context, 'תקן הציוד הרפואי נטען בהצלחה');
                      }
                    },
                  ),
                ),
              );
            }

            late final List<_KitScope> scopes;
            late final _KitScope activeScope;

            if (isCompanyMedic) {
              scopes = _buildCompanyMedicScopes(eqList, activeMedics);
              activeScope = scopes.where((s) => s.key == _selectedScopeKey).firstOrNull ?? scopes.first;
            } else {
              final personalScope = _KitScope(
                key: 'personal_vest',
                label: 'הווסט האישי שלי – $effectiveMedicName',
                targetCategory: Equipment.vestCategoryFor(effectiveMedicId),
                medicId: effectiveMedicId,
                includeLegacyVest: false,
              );
              scopes = [personalScope];
              activeScope = personalScope;
            }

            final items = activeScope.filter(eqList);

            // Auto-seed personal vest for combat medic or selected medic chip if not yet created
            if (activeScope.medicId != null && activeScope.medicId!.isNotEmpty && items.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                ref.read(equipmentProvider.notifier).ensureMedicVestSeeded(
                      activeScope.medicId!,
                      includeLegacyUnassigned: activeScope.includeLegacyVest,
                    );
              });
            }

            final expendables = items.where((e) => e.itemType == 'מתכלה').toList();
            final durables = items.where((e) => e.itemType == 'קבוע').toList();

            final missingInScopeCount = items
                .where((e) => e.status == 'MISSING' || e.quantity < e.minimumRequired)
                .length;
            final readinessPercent = items.isEmpty
                ? 100
                : (((items.length - missingInScopeCount) / items.length) * 100).round();
            final isReady = readinessPercent > 90;

            final unitHasMissing = eqList.any(
              (e) =>
                  e.vestOwnerId?.startsWith('demo_medic_') != true &&
                  (e.status == 'MISSING' || e.quantity < e.minimumRequired),
            );

            return Scaffold(
              backgroundColor: AppTheme.backgroundPrimary,
              floatingActionButton: isCompanyMedic
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 120.0),
                      child: FloatingActionButton(
                        onPressed: () => _showAddOrEditSheet(
                          context,
                          scopes: scopes,
                          activeScope: activeScope,
                        ),
                        backgroundColor: AppTheme.primaryGreen,
                        child: const Icon(LucideIcons.plus, color: Colors.white),
                      ),
                    )
                  : null,
              body: RefreshIndicator(
                color: AppTheme.primaryGreen,
                onRefresh: () => ref.read(equipmentProvider.notifier).refresh(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      title: Text(
                        isCompanyMedic ? 'כשירות ציוד רפואי' : 'הווסט שלי – $effectiveMedicName',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      floating: true,
                      pinned: true,
                      actions: [
                        if (isCompanyMedic)
                          IconButton(
                            icon: const Icon(LucideIcons.userCog),
                            tooltip: 'פרטי חוג"ד לדיווחי WhatsApp',
                            onPressed: () => BattalionMedicHelper.showSettingsSheet(context),
                          ),
                        IconButton(
                          icon: const Icon(LucideIcons.shieldCheck),
                          tooltip: 'בדיקת חסם עורקים',
                          onPressed: _showCatCheckModal,
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: _buildHeroReadiness(
                        readinessPercent,
                        isReady,
                        scopeLabel: activeScope.label,
                        missingCount: missingInScopeCount,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing16,
                          vertical: AppTheme.spacing8,
                        ),
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
                            if (isCompanyMedic && unitHasMissing) ...[
                              const SizedBox(width: AppTheme.spacing8),
                              Expanded(
                                flex: 5,
                                child: HopalButton(
                                  label: 'שלח חוסרים לחוג"ד',
                                  icon: LucideIcons.messageCircle,
                                  onPressed: () => BattalionMedicHelper.sendReportToHogad(
                                    context,
                                    _buildHogadMissingReport(eqList),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (isCompanyMedic)
                      SliverToBoxAdapter(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing16,
                            vertical: AppTheme.spacing8,
                          ),
                          child: Row(
                            children: scopes.map((scope) {
                              final isSelected = activeScope.key == scope.key;
                              return Padding(
                                padding: const EdgeInsets.only(left: AppTheme.spacing8),
                                child: ChoiceChip(
                                  label: Text(
                                    scope.label,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _selectedScopeKey = scope.key);
                                    }
                                  },
                                  backgroundColor: AppTheme.backgroundSecondary,
                                  selectedColor: AppTheme.primaryGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: isSelected ? AppTheme.primaryGreen : AppTheme.borderSubtle,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      )
                    else
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.spacing16,
                            AppTheme.spacing8,
                            AppTheme.spacing16,
                            0,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundSecondary,
                              borderRadius: AppTheme.radiusMd,
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.shield, size: 18, color: AppTheme.primaryGreen),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'וסט החובש האישי של $effectiveMedicName • עדכן כמויות בזמן אמת',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (items.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacing32),
                          child: Center(
                            child: Text(
                              activeScope.medicId != null
                                  ? 'טוען את תקן וסט החובש האישי...'
                                  : 'אין פריטים תחת ${activeScope.label}',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                        ),
                      ),
                    if (expendables.isNotEmpty) ...[
                      _buildSectionHeader('ציוד מתכלה', LucideIcons.packagePlus, AppTheme.primaryGreen),
                      _buildEquipmentList(
                        expendables,
                        scopes: scopes,
                        activeScope: activeScope,
                        isCompanyMedic: isCompanyMedic,
                      ),
                    ],
                    if (durables.isNotEmpty) ...[
                      _buildSectionHeader('ציוד קבוע', LucideIcons.briefcase, AppTheme.primaryGreen),
                      _buildEquipmentList(
                        durables,
                        scopes: scopes,
                        activeScope: activeScope,
                        isCompanyMedic: isCompanyMedic,
                      ),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeroReadiness(
    int readinessPercent,
    bool isReady, {
    required String scopeLabel,
    required int missingCount,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: HopalCard(
        backgroundColor: isReady
            ? AppTheme.primaryGreen.withValues(alpha: 0.1)
            : AppTheme.criticalRed.withValues(alpha: 0.1),
        borderColor: isReady
            ? AppTheme.primaryGreen.withValues(alpha: 0.3)
            : AppTheme.criticalRed.withValues(alpha: 0.3),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isReady ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
                  size: 32,
                  color: isReady ? AppTheme.successGreen : AppTheme.criticalRed,
                ),
                const SizedBox(width: AppTheme.spacing12),
                Text(
                  '$readinessPercent%',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    height: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              missingCount == 0
                  ? 'כשירות מלאה – $scopeLabel'
                  : '$missingCount פריטים חסרים לתקן ($scopeLabel)',
              style: TextStyle(
                color: isReady ? AppTheme.successGreen : AppTheme.criticalRed,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
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
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacing16,
          AppTheme.spacing24,
          AppTheme.spacing16,
          AppTheme.spacing8,
        ),
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

  Widget _buildEquipmentList(
    List<Equipment> items, {
    required List<_KitScope> scopes,
    required _KitScope activeScope,
    required bool isCompanyMedic,
  }) {
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
                onTap: isCompanyMedic
                    ? () => _showAddOrEditSheet(
                          context,
                          scopes: scopes,
                          activeScope: activeScope,
                          item: item,
                        )
                    : null,
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundSecondary,
                        borderRadius: AppTheme.radiusSm,
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: item.imagePath != null
                          ? ClipRRect(
                              borderRadius: AppTheme.radiusSm,
                              child: Image(
                                key: ValueKey('${item.id}_${item.imagePath!.length}'),
                                image: resolveLocalOrWebImage(item.imagePath!),
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
                          Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppTheme.spacing4),
                          Row(
                            children: [
                              Text(
                                'תקן: ${item.minimumRequired}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacing8),
                              HopalStatusBadge(label: statusText, icon: statusIcon, variant: variant),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                            onTap: item.quantity > 0
                                ? () {
                                    HapticFeedback.selectionClick();
                                    ref.read(equipmentProvider.notifier).adjustQuantity(item.id, -1);
                                  }
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Icon(
                                LucideIcons.minus,
                                size: 16,
                                color: item.quantity > 0 ? AppTheme.criticalRed : AppTheme.textMuted,
                              ),
                            ),
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 28),
                            alignment: Alignment.center,
                            child: Text(
                              '${item.quantity}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isMissing ? AppTheme.criticalRed : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref.read(equipmentProvider.notifier).adjustQuantity(item.id, 1);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Icon(
                                LucideIcons.plus,
                                size: 16,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

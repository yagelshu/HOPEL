import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/core/ai/medical_copilot_service.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/core/utils/equipment_photo_catalog.dart';
import 'package:chopel_app/core/utils/platform_image.dart';
import 'package:chopel_app/models/equipment.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';

class DispensedItem {
  final String equipmentId;
  final String name;
  final String sourceLabel;
  final int quantity;

  const DispensedItem({
    required this.equipmentId,
    required this.name,
    required this.sourceLabel,
    required this.quantity,
  });

  DispensedItem copyWith({int? quantity}) => DispensedItem(
        equipmentId: equipmentId,
        name: name,
        sourceLabel: sourceLabel,
        quantity: quantity ?? this.quantity,
      );
}

class InventoryDispenseHelper {
  static String formatDispensedSummary(List<DispensedItem> items) {
    final active = items.where((i) => i.quantity > 0).toList();
    if (active.isEmpty) return '';
    final parts = active.map((i) => '${i.name} (x${i.quantity})').join(', ');
    return '💊 נופק מהמלאי: $parts';
  }

  /// Checks if [itemName] is contraindicated for a soldier with [soldierAllergies].
  /// Returns a clear Hebrew warning string if blocked, or `null` if safe to dispense.
  static String? getAllergyBlockReason(String itemName, String? soldierAllergies) {
    final cleanAlg = (soldierAllergies ?? '').trim();
    if (cleanAlg.isEmpty) return null;

    final check = MedicalCopilotService.checkAllergyConflicts(
      allergies: cleanAlg,
      recommendedMedications: [itemName],
    );
    if (check.safeMedications.isEmpty && check.warnings.isNotEmpty) {
      return check.warnings.first;
    }

    final lowerItem = itemName.toLowerCase();
    final lowerAlg = cleanAlg.toLowerCase();

    if ((lowerAlg.contains('g6pd') || lowerAlg.contains('פול') || lowerAlg.contains('אופטלגין')) &&
        (lowerItem.contains('אופטלגין') || lowerItem.contains('dipyrone'))) {
      return 'אסור לניפוק לחייל עם רגישות G6PD / אופטלגין!';
    }
    if ((lowerAlg.contains('אקמול') || lowerAlg.contains('פראצטמול') || lowerAlg.contains('פרצטמול')) &&
        (lowerItem.contains('אקמול') || lowerItem.contains('פראצטמול'))) {
      return 'אסור לניפוק לחייל עם רגישות לאקמול / פראצטמול!';
    }
    if ((lowerAlg.contains('פניצילין') || lowerAlg.contains('מוקסיפן')) &&
        (lowerItem.contains('פניצילין') || lowerItem.contains('מוקסיפן') || lowerItem.contains('אוגמנטין'))) {
      return 'אסור לניפוק לחייל עם אלרגיה לפניצילין!';
    }
    if ((lowerAlg.contains('nsaid') || lowerAlg.contains('נורופן') || lowerAlg.contains('איבופרופן')) &&
        (lowerItem.contains('נורופן') || lowerItem.contains('אדוויל') || lowerItem.contains('איבופרופן') || lowerItem.contains('וולטרן'))) {
      return 'אסור לניפוק לחייל עם רגישות ל-NSAID!';
    }

    return null;
  }

  static Future<List<DispensedItem>?> showPickerSheet(
    BuildContext context, {
    required List<Equipment> allEquipment,
    List<DispensedItem> initialSelection = const [],
    String? soldierName,
    String? soldierAllergies,
  }) async {
    final currentUserId = AuthService().effectiveUserId ?? AuthService().currentUser?.id ?? 'hopal';
    final isCompanyMedic = AuthService().isCompanyMedic;

    // Filter to company box + current medic's vest
    final relevantEquipment = allEquipment.where((eq) {
      if (isCompanyMedic && eq.isCompanyBox) return true;
      if (eq.belongsToMedicVest(currentUserId, includeLegacyUnassigned: isCompanyMedic)) return true;
      return false;
    }).toList();

    final Map<String, int> selectedCounts = {
      for (final d in initialSelection)
        if (d.quantity > 0) d.equipmentId: d.quantity,
    };

    String searchQuery = '';
    String scopeFilter = isCompanyMedic ? 'box' : 'vest'; // 'box' | 'vest' | 'all'
    final searchController = TextEditingController();
    final hasAllergies = soldierAllergies != null && soldierAllergies.trim().isNotEmpty;

    return showModalBottomSheet<List<DispensedItem>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setModalState) {
            final q = searchQuery.trim().toLowerCase();
            final filtered = relevantEquipment.where((eq) {
              if (scopeFilter == 'box' && !eq.isCompanyBox) return false;
              if (scopeFilter == 'vest' && eq.isCompanyBox) return false;
              if (q.isNotEmpty && !eq.name.toLowerCase().contains(q)) return false;
              return true;
            }).toList();

            // Put already-selected items or in-stock items first
            filtered.sort((a, b) {
              final aSel = (selectedCounts[a.id] ?? 0) > 0;
              final bSel = (selectedCounts[b.id] ?? 0) > 0;
              if (aSel && !bSel) return -1;
              if (!aSel && bSel) return 1;
              if (a.quantity > 0 && b.quantity == 0) return -1;
              if (a.quantity == 0 && b.quantity > 0) return 1;
              return a.name.compareTo(b.name);
            });

            final totalSelectedItems = selectedCounts.values.where((v) => v > 0).length;

            return Container(
              height: MediaQuery.of(sheetCtx).size.height * 0.80,
              padding: EdgeInsets.only(
                top: AppTheme.spacing16,
                left: AppTheme.spacing16,
                right: AppTheme.spacing16,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + AppTheme.spacing16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.packageMinus, color: AppTheme.primaryGreen, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ניפוק תרופה / ציוד מהמלאי',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.x, color: AppTheme.textSecondary),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  if (hasAllergies) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.criticalRed.withValues(alpha: 0.15),
                        borderRadius: AppTheme.radiusMd,
                        border: Border.all(color: AppTheme.criticalRed.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.shieldAlert, color: AppTheme.criticalRed, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'רגישות מתועדת${soldierName != null ? ' ($soldierName)' : ''}: $soldierAllergies • תרופות אסורות נחסמו אוטומטית',
                              style: TextStyle(
                                color: AppTheme.criticalRed,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (isCompanyMedic)
                    Row(
                      children: [
                        _buildScopeChip(
                          label: 'ארגז חופ"ל',
                          selected: scopeFilter == 'box',
                          onTap: () => setModalState(() => scopeFilter = 'box'),
                        ),
                        const SizedBox(width: 8),
                        _buildScopeChip(
                          label: 'הווסט שלי',
                          selected: scopeFilter == 'vest',
                          onTap: () => setModalState(() => scopeFilter = 'vest'),
                        ),
                        const SizedBox(width: 8),
                        _buildScopeChip(
                          label: 'הכל',
                          selected: scopeFilter == 'all',
                          onTap: () => setModalState(() => scopeFilter = 'all'),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: searchController,
                    style: TextStyle(color: AppTheme.textPrimary),
                    onChanged: (val) => setModalState(() => searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'חפש תרופה או פריט ציוד (למשל: אקמול, תחבושת)...',
                      prefixIcon: Icon(LucideIcons.search, color: AppTheme.textSecondary, size: 18),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(LucideIcons.x, size: 16, color: AppTheme.textSecondary),
                              onPressed: () {
                                searchController.clear();
                                setModalState(() => searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.backgroundTertiary,
                      border: const OutlineInputBorder(
                        borderRadius: AppTheme.radiusMd,
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'לא נמצאו פריטים תואמים במלאי',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (ctx, idx) {
                              final eq = filtered[idx];
                              final count = selectedCounts[eq.id] ?? 0;
                              final isSelected = count > 0;
                              final sourceStr = eq.isCompanyBox ? 'ארגז חופ"ל' : 'הווסט שלי';
                              final outOfStock = eq.quantity <= 0;
                              final blockReason = getAllergyBlockReason(eq.name, soldierAllergies);
                              final isBlockedByAllergy = blockReason != null;
                              final photoPath = eq.imagePath ?? EquipmentPhotoCatalog.resolveBuiltInPhoto(eq.name);

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isBlockedByAllergy
                                      ? AppTheme.criticalRed.withValues(alpha: 0.12)
                                      : isSelected
                                          ? AppTheme.primaryGreen.withValues(alpha: 0.14)
                                          : AppTheme.backgroundPrimary,
                                  borderRadius: AppTheme.radiusMd,
                                  border: Border.all(
                                    color: isBlockedByAllergy
                                        ? AppTheme.criticalRed.withValues(alpha: 0.65)
                                        : isSelected
                                            ? AppTheme.primaryGreen
                                            : AppTheme.borderSubtle,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      padding: photoPath != null ? const EdgeInsets.all(2) : EdgeInsets.zero,
                                      decoration: BoxDecoration(
                                        color: photoPath != null ? Colors.white : AppTheme.backgroundSecondary,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppTheme.borderSubtle),
                                      ),
                                      child: photoPath != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(5),
                                              child: Image(
                                                image: resolveLocalOrWebImage(photoPath),
                                                fit: BoxFit.contain,
                                                errorBuilder: (_, __, ___) => Icon(
                                                  LucideIcons.pill,
                                                  size: 18,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                            )
                                          : Icon(
                                              eq.itemType == 'מתכלה' ? LucideIcons.pill : LucideIcons.briefcase,
                                              size: 18,
                                              color: AppTheme.textSecondary,
                                            ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            eq.name,
                                            style: TextStyle(
                                              color: isBlockedByAllergy
                                                  ? AppTheme.criticalRed
                                                  : (outOfStock ? AppTheme.textMuted : AppTheme.textPrimary),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          if (isBlockedByAllergy)
                                            Text(
                                              '⛔ $blockReason',
                                              style: TextStyle(
                                                color: AppTheme.criticalRed,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          else
                                            Text(
                                              '$sourceStr • במלאי: ${eq.quantity}${isSelected ? ' (יישאר: ${(eq.quantity - count).clamp(0, 9999)})' : ''}',
                                              style: TextStyle(
                                                color: outOfStock
                                                    ? AppTheme.criticalRed
                                                    : (isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary),
                                                fontSize: 12,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (isBlockedByAllergy)
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: Icon(LucideIcons.shieldAlert, color: AppTheme.criticalRed, size: 22),
                                        onPressed: () {
                                          HopalFeedback.showError(sheetCtx, blockReason);
                                        },
                                      )
                                    else
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isSelected) ...[
                                            IconButton(
                                              visualDensity: VisualDensity.compact,
                                              icon: Icon(LucideIcons.minusCircle, color: AppTheme.criticalRed, size: 20),
                                              onPressed: () {
                                                setModalState(() {
                                                  if (count <= 1) {
                                                    selectedCounts.remove(eq.id);
                                                  } else {
                                                    selectedCounts[eq.id] = count - 1;
                                                  }
                                                });
                                              },
                                            ),
                                            Container(
                                              constraints: const BoxConstraints(minWidth: 26),
                                              alignment: Alignment.center,
                                              child: Text(
                                                '$count',
                                                style: TextStyle(
                                                  color: AppTheme.textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                          ],
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            icon: Icon(
                                              LucideIcons.plusCircle,
                                              color: outOfStock ? AppTheme.textMuted : AppTheme.primaryGreen,
                                              size: 22,
                                            ),
                                            onPressed: outOfStock
                                                ? null
                                                : () {
                                                    setModalState(() {
                                                      final next = (count + 1).clamp(0, eq.quantity);
                                                      if (next > 0) {
                                                        selectedCounts[eq.id] = next;
                                                      }
                                                    });
                                                  },
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  HopalButton(
                    label: totalSelectedItems > 0
                        ? 'אשר ניפוק ($totalSelectedItems סוגי פריטים)'
                        : 'סגור ללא ניפוק',
                    icon: LucideIcons.check,
                    onPressed: () {
                      final result = <DispensedItem>[];
                      for (final entry in selectedCounts.entries) {
                        if (entry.value <= 0) continue;
                        final eq = relevantEquipment.where((e) => e.id == entry.key).firstOrNull;
                        if (eq != null) {
                          result.add(
                            DispensedItem(
                              equipmentId: eq.id,
                              name: eq.name,
                              sourceLabel: eq.isCompanyBox ? 'ארגז חופ"ל' : 'הווסט שלי',
                              quantity: entry.value,
                            ),
                          );
                        }
                      }
                      Navigator.pop(sheetCtx, result);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildScopeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryGreen : AppTheme.backgroundTertiary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppTheme.primaryGreen : AppTheme.borderSubtle,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppTheme.onPrimaryGreen : AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}

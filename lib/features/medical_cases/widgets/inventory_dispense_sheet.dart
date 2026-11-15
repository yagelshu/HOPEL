import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/models/equipment.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';

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

  static Future<List<DispensedItem>?> showPickerSheet(
    BuildContext context, {
    required List<Equipment> allEquipment,
    List<DispensedItem> initialSelection = const [],
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
              height: MediaQuery.of(sheetCtx).size.height * 0.78,
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
                  Text(
                    'בחר פריטים שנופקו לחייל. הכמות תופחת אוטומטית מהמלאי ותירשם בתיק הפנייה:',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
                  ),
                  const SizedBox(height: 12),
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

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryGreen.withValues(alpha: 0.14)
                                      : AppTheme.backgroundPrimary,
                                  borderRadius: AppTheme.radiusMd,
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primaryGreen : AppTheme.borderSubtle,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            eq.name,
                                            style: TextStyle(
                                              color: outOfStock ? AppTheme.textMuted : AppTheme.textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
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


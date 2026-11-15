import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:chopel_app/core/services/battalion_staff_service.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_bottom_sheet.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:chopel_app/theme/components/hopal_text_field.dart';

class BattalionMedicHelper {
  static const String prefNameKey = 'hogad_name';
  static const String prefPhoneKey = 'hogad_phone_number';

  static Future<(String name, String phone)> loadSaved() async {
    final active = await BattalionStaffService.getActiveContact(BattalionStaffService.groupHogad);
    if (active != null) {
      return (active.name, active.phone);
    }
    return ('', '');
  }

  static Future<void> save({required String name, required String phone, String role = 'חוג"ד'}) async {
    final active = await BattalionStaffService.getActiveContact(BattalionStaffService.groupHogad);
    await BattalionStaffService.upsertContact(
      StaffContact(
        id: active?.id ?? const Uuid().v4(),
        name: name.trim(),
        phone: phone.trim(),
        role: role,
        group: BattalionStaffService.groupHogad,
        isOnDuty: true,
      ),
    );
  }

  static Future<void> _openWhatsAppWithPhone(
    BuildContext context,
    String rawPhone,
    String message,
  ) async {
    String clean = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith('0')) {
      clean = '972${clean.substring(1)}';
    }
    final waUri = Uri.parse('https://wa.me/$clean?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(waUri)) {
      await launchUrl(waUri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      await SharePlus.instance.share(ShareParams(text: message));
    }
  }

  /// Sends [message] to the active חוג"ד (or מחליף חוג"ד) on duty, or lets the medic pick if multiple exist.
  static Future<void> sendReportToHogad(
    BuildContext context,
    String message, {
    VoidCallback? onContactUpdated,
  }) async {
    final hogadList = await BattalionStaffService.loadGroup(BattalionStaffService.groupHogad);
    if (!context.mounted) return;

    if (hogadList.isEmpty) {
      await _showFirstHogadPrompt(context, message, onContactUpdated: onContactUpdated);
      return;
    }

    if (hogadList.length == 1) {
      await _openWhatsAppWithPhone(context, hogadList.first.phone, message);
      return;
    }

    // Multiple Hogad / replacement contacts exist -> show fast recipient selector
    await _showHogadRecipientPicker(
      context,
      hogadList: hogadList,
      message: message,
      onContactUpdated: onContactUpdated,
    );
  }

  static Future<void> _showHogadRecipientPicker(
    BuildContext context, {
    required List<StaffContact> hogadList,
    required String message,
    VoidCallback? onContactUpdated,
  }) async {
    List<StaffContact> currentList = List<StaffContact>.from(hogadList);

    await HopalBottomSheet.show(
      context: context,
      title: 'בחירת חוג"ד / מחליף לדיווח (WhatsApp)',
      child: StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final active = currentList.where((c) => c.isOnDuty).firstOrNull ?? currentList.first;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'בחר למי לשלוח את הדיווח (חוג"ד או מחליף חוג"ד בתורנות):',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: AppTheme.spacing16),
              HopalButton(
                label: 'שלח לתורן הפעיל: ${active.displayLabel}',
                icon: LucideIcons.messageCircle,
                onPressed: () async {
                  Navigator.pop(sheetCtx);
                  await _openWhatsAppWithPhone(context, active.phone, message);
                },
              ),
              const SizedBox(height: AppTheme.spacing16),
              ...currentList.map((contact) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: contact.isOnDuty
                        ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                        : AppTheme.backgroundPrimary,
                    borderRadius: AppTheme.radiusMd,
                    border: Border.all(
                      color: contact.isOnDuty ? AppTheme.primaryGreen : AppTheme.borderSubtle,
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                      child: Icon(LucideIcons.shield, size: 16, color: AppTheme.primaryGreen),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            contact.name.isNotEmpty ? contact.name : contact.role,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundTertiary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            contact.role,
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (contact.isOnDuty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'בתורנות 🟢',
                              style: TextStyle(color: AppTheme.successGreen, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      contact.phone,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!contact.isOnDuty)
                          TextButton(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onPressed: () async {
                              await BattalionStaffService.setOnDuty(
                                contact.id,
                                BattalionStaffService.groupHogad,
                              );
                              final refreshed = await BattalionStaffService.loadGroup(
                                BattalionStaffService.groupHogad,
                              );
                              onContactUpdated?.call();
                              setSheetState(() {
                                currentList = refreshed;
                              });
                            },
                            child: Text(
                              'הגדר כתורן',
                              style: TextStyle(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        IconButton(
                          icon: Icon(LucideIcons.send, size: 18, color: AppTheme.primaryGreen),
                          tooltip: 'שלח ב-WhatsApp',
                          onPressed: () async {
                            Navigator.pop(sheetCtx);
                            await _openWhatsAppWithPhone(context, contact.phone, message);
                          },
                        ),
                      ],
                    ),
                    onTap: () async {
                      Navigator.pop(sheetCtx);
                      await _openWhatsAppWithPhone(context, contact.phone, message);
                    },
                  ),
                );
              }),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      showSettingsSheet(context, onSaved: onContactUpdated);
                    },
                    icon: Icon(LucideIcons.settings, size: 15, color: AppTheme.textSecondary),
                    label: Text('ניהול חוג"ד ומחליפים', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetCtx);
                      await SharePlus.instance.share(ShareParams(text: message));
                    },
                    icon: Icon(LucideIcons.share2, size: 15, color: AppTheme.textSecondary),
                    label: Text('שיתוף כללי', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _showFirstHogadPrompt(
    BuildContext context,
    String message, {
    VoidCallback? onContactUpdated,
  }) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'חוג"ד';

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.backgroundSecondary,
          title: Row(
            children: [
              Icon(LucideIcons.messageCircle, color: AppTheme.primaryGreen, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'הגדרת חוג"ד / מחליף חוג"ד',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'הזן את מספר הטלפון של החוג"ד (או מחליף החוג"ד) כדי שדיווחי המצבת והציוד ייפתחו ישירות ב-WhatsApp:',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: AppTheme.spacing12),
                Row(
                  children: BattalionStaffService.hogadRoles.map((role) {
                    final isSelected = selectedRole == role;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Center(child: Text(role)),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryGreen,
                          checkmarkColor: AppTheme.onPrimaryGreen,
                          backgroundColor: AppTheme.backgroundTertiary,
                          labelStyle: TextStyle(
                            color: isSelected ? AppTheme.onPrimaryGreen : AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          onSelected: (_) => setDialogState(() => selectedRole = role),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppTheme.spacing12),
                HopalTextField(
                  controller: nameController,
                  hint: 'שם החוג"ד (אופציונלי)',
                  icon: LucideIcons.user,
                ),
                const SizedBox(height: AppTheme.spacing12),
                HopalTextField(
                  controller: phoneController,
                  hint: 'מספר טלפון (למשל: 0501234567)',
                  icon: LucideIcons.phone,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                await SharePlus.instance.share(ShareParams(text: message));
              },
              child: Text('שיתוף כללי', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: AppTheme.onPrimaryGreen,
              ),
              onPressed: () async {
                final phone = phoneController.text.trim();
                if (phone.replaceAll(RegExp(r'\D'), '').length < 9) {
                  HopalFeedback.showError(dialogCtx, 'נא להזין מספר טלפון תקין של החוג"ד');
                  return;
                }
                await BattalionStaffService.upsertContact(
                  StaffContact(
                    id: const Uuid().v4(),
                    name: nameController.text.trim(),
                    phone: phone,
                    role: selectedRole,
                    group: BattalionStaffService.groupHogad,
                    isOnDuty: true,
                  ),
                );
                onContactUpdated?.call();
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (context.mounted) {
                  await _openWhatsAppWithPhone(context, phone, message);
                }
              },
              child: const Text('שמור ופתח WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens a full settings sheet to manage חוג"ד and מחליף חוג"ד contacts & active shift.
  static Future<void> showSettingsSheet(
    BuildContext context, {
    VoidCallback? onSaved,
  }) async {
    List<StaffContact> contacts = await BattalionStaffService.loadGroup(BattalionStaffService.groupHogad);
    if (!context.mounted) return;

    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = contacts.isEmpty ? 'חוג"ד' : 'מחליף חוג"ד';
    bool markOnDuty = contacts.isEmpty;
    String? editingId;

    await HopalBottomSheet.show(
      context: context,
      title: 'סגל חוג"ד ומחליפים (WhatsApp)',
      child: StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          Future<void> reload() async {
            final updated = await BattalionStaffService.loadGroup(BattalionStaffService.groupHogad);
            onSaved?.call();
            if (sheetCtx.mounted) {
              setSheetState(() {
                contacts = updated;
              });
            }
          }

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'הגדר את החוג"ד ואת מחליף החוג"ד. סמן מי נמצא כעת בתורנות כדי שדיווחי מצבת חובשים ודרישות ציוד יישלחו אליו.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: AppTheme.spacing16),
                if (contacts.isNotEmpty) ...[
                  Text(
                    'חוג"ד ומחליפים רשומים (${contacts.length}):',
                    style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  ...contacts.map((c) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: c.isOnDuty
                            ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                            : AppTheme.backgroundPrimary,
                        borderRadius: AppTheme.radiusMd,
                        border: Border.all(
                          color: c.isOnDuty ? AppTheme.primaryGreen : AppTheme.borderSubtle,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                            child: Icon(LucideIcons.shield, size: 16, color: AppTheme.primaryGreen),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      c.name.isNotEmpty ? c.name : c.role,
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.backgroundTertiary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        c.role,
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (c.isOnDuty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.successGreen.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'בתורנות כעת 🟢',
                                          style: TextStyle(
                                            color: AppTheme.successGreen,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  c.phone,
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (!c.isOnDuty)
                            TextButton(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              onPressed: () async {
                                await BattalionStaffService.setOnDuty(c.id, BattalionStaffService.groupHogad);
                                await reload();
                              },
                              child: Text(
                                'סמן כתורן',
                                style: TextStyle(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(LucideIcons.pencil, size: 16, color: AppTheme.textSecondary),
                            tooltip: 'ערוך',
                            onPressed: () {
                              setSheetState(() {
                                editingId = c.id;
                                nameController.text = c.name;
                                phoneController.text = c.phone;
                                selectedRole = c.role;
                                markOnDuty = c.isOnDuty;
                              });
                            },
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(LucideIcons.trash2, size: 16, color: AppTheme.criticalRed),
                            tooltip: 'מחק',
                            onPressed: () async {
                              await BattalionStaffService.deleteContact(c.id);
                              if (editingId == c.id) {
                                editingId = null;
                                nameController.clear();
                                phoneController.clear();
                              }
                              await reload();
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 24),
                ],
                Text(
                  editingId == null ? 'הוספת חוג"ד / מחליף חוג"ד:' : 'עריכת פרטי חוג"ד:',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Row(
                  children: BattalionStaffService.hogadRoles.map((role) {
                    final isSelected = selectedRole == role;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Center(child: Text(role)),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryGreen,
                          checkmarkColor: AppTheme.onPrimaryGreen,
                          backgroundColor: AppTheme.backgroundTertiary,
                          labelStyle: TextStyle(
                            color: isSelected ? AppTheme.onPrimaryGreen : AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          onSelected: (_) => setSheetState(() => selectedRole = role),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                HopalTextField(
                  controller: nameController,
                  hint: 'שם החוג"ד / המחליף (לדוגמה: רס"ל דניאל)',
                  icon: LucideIcons.user,
                ),
                const SizedBox(height: 10),
                HopalTextField(
                  controller: phoneController,
                  hint: 'מספר טלפון ל-WhatsApp (למשל: 0501234567)',
                  icon: LucideIcons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: markOnDuty,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppTheme.primaryGreen,
                  title: Text(
                    'סמן כחוג"ד בתורנות פעילה כעת 🟢',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  onChanged: (v) => setSheetState(() => markOnDuty = v ?? false),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (editingId != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {
                              editingId = null;
                              nameController.clear();
                              phoneController.clear();
                              markOnDuty = false;
                            });
                          },
                          child: const Text('ביטול עריכה'),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      flex: 2,
                      child: HopalButton(
                        label: editingId == null ? 'הוסף חוג"ד / מחליף' : 'שמור שינויים',
                        icon: editingId == null ? LucideIcons.userPlus : LucideIcons.check,
                        onPressed: () async {
                          final phone = phoneController.text.trim();
                          if (phone.replaceAll(RegExp(r'\D'), '').length < 9) {
                            HopalFeedback.showError(sheetCtx, 'נא להזין מספר טלפון תקין');
                            return;
                          }
                          await BattalionStaffService.upsertContact(
                            StaffContact(
                              id: editingId ?? const Uuid().v4(),
                              name: nameController.text.trim(),
                              phone: phone,
                              role: selectedRole,
                              group: BattalionStaffService.groupHogad,
                              isOnDuty: markOnDuty || contacts.isEmpty,
                            ),
                          );
                          nameController.clear();
                          phoneController.clear();
                          editingId = null;
                          markOnDuty = false;
                          await reload();
                          if (context.mounted) {
                            HopalFeedback.showSuccess(context, 'סגל החוג"ד עודכן בהצלחה');
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing16),
              ],
            ),
          );
        },
      ),
    );
  }
}

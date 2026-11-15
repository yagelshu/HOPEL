import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:chopel_app/core/services/battalion_staff_service.dart';
import 'package:chopel_app/core/utils/image_data_uri_helper.dart';
import 'package:chopel_app/models/medical_case.dart';
import 'package:chopel_app/models/soldier.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/core/utils/platoon_helper.dart';
import 'package:chopel_app/theme/components/hopal_bottom_sheet.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:chopel_app/theme/components/hopal_text_field.dart';

/// Shared helper to consult the battalion senior medical provider — מט"ב (רופא / פראמדיק בתורנות)
/// over WhatsApp using the saved Matab contacts, consistent across Dashboard & Case Detail screens.
class DoctorConsultHelper {
  static const String prefDoctorPhoneKey = 'doctor_phone_number';
  static const String prefDoctorNameKey = 'doctor_name';

  static String formatPhoneForWhatsApp(String rawPhone) {
    String cleanPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '972${cleanPhone.substring(1)}';
    }
    return cleanPhone;
  }

  static String buildMedicalCaseMessage({
    required MedicalCase medicalCase,
    Soldier? soldier,
    String? fallbackSoldierName,
    String? descriptionOverride,
    String? statusOverride,
  }) {
    final name = soldier?.name ?? fallbackSoldierName ?? 'חייל לא ידוע';
    final pnPart = (soldier?.personalNumber != null && soldier!.personalNumber!.isNotEmpty)
        ? ' (מ.א ${soldier.personalNumber})'
        : '';
    final platoonPart = (soldier?.platoon != null && soldier!.platoon!.trim().isNotEmpty)
        ? ' | ${PlatoonHelper.formatDisplay(soldier.platoon)}'
        : '';
    final soldierLabel = '$name$pnPart$platoonPart';

    final category = medicalCase.category ?? 'שגרת מרפאה';
    final severity = medicalCase.severity ?? 'שגרה';
    final effectiveStatus = statusOverride ?? medicalCase.status;
    final statusHeb = effectiveStatus == 'COMPLETED' ? 'הושלם' : 'בטיפול / מעקב';
    final desc = (descriptionOverride ?? medicalCase.description ?? 'אין תיאור').trim();

    final buffer = StringBuffer();
    buffer.writeln('📋 *פנייה רפואית - חופ"ל*');
    buffer.writeln('👤 *חייל:* $soldierLabel');
    if (soldier != null && soldier.hasAllergies) {
      buffer.writeln('🚨 *רגישות ידועה:* ${soldier.allergies}');
    }
    buffer.writeln('🏷️ *קטגוריה:* $category | *דחיפות:* $severity');
    buffer.writeln('🩺 *תלונה וסיכום:*');
    buffer.writeln(desc.isEmpty ? 'אין תיאור' : desc);
    buffer.writeln('📌 *סטטוס:* $statusHeb');
    if (medicalCase.imagePath != null && medicalCase.imagePath!.isNotEmpty) {
      buffer.writeln('📷 *מצורף צילום בתיק האפליקציה*');
    }
    buffer.writeln('\nאשמח להנחיות מט"ב / רופא.');
    return buffer.toString();
  }

  static Future<void> _shareSafely(String message, String? imagePath) async {
    if (!kIsWeb && ImageDataUriHelper.isLocalFilesystemPath(imagePath)) {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(imagePath!)], text: message),
      );
    } else {
      await SharePlus.instance.share(ShareParams(text: message));
    }
  }

  static Future<void> _launchWhatsAppForPhone(
    BuildContext context,
    String rawPhone,
    String message,
    String? imagePath,
  ) async {
    final cleanPhone = formatPhoneForWhatsApp(rawPhone);
    if (cleanPhone.isNotEmpty) {
      final waUrl = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(waUrl)) {
        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
        return;
      }
    }
    if (context.mounted) {
      await _shareSafely(message, imagePath);
    }
  }

  static Future<void> shareMedicalCase(
    BuildContext context, {
    required MedicalCase medicalCase,
    Soldier? soldier,
    String? fallbackSoldierName,
    String? descriptionOverride,
    String? statusOverride,
  }) async {
    final message = buildMedicalCaseMessage(
      medicalCase: medicalCase,
      soldier: soldier,
      fallbackSoldierName: fallbackSoldierName,
      descriptionOverride: descriptionOverride,
      statusOverride: statusOverride,
    );

    await sendMessageToMatab(
      context,
      message,
      imagePath: medicalCase.imagePath,
    );
  }

  /// Sends any clinical message (single case, outbreak alert, or daily Matab queue) to the Matab on duty.
  static Future<void> sendMessageToMatab(
    BuildContext context,
    String message, {
    String? imagePath,
    VoidCallback? onContactUpdated,
  }) async {
    final matabList = await BattalionStaffService.loadGroup(BattalionStaffService.groupMatab);

    if (!context.mounted) return;

    if (matabList.isEmpty) {
      _showAddFirstMatabPrompt(context, message, imagePath, onContactUpdated: onContactUpdated);
      return;
    }

    if (matabList.length == 1) {
      await _launchWhatsAppForPhone(context, matabList.first.phone, message, imagePath);
      return;
    }

    // Multiple Matab providers configured (e.g. 2 doctors + 2 paramedics) -> show fast selector
    await _showMatabRecipientPicker(
      context,
      matabList: matabList,
      message: message,
      imagePath: imagePath,
      onContactUpdated: onContactUpdated,
    );
  }

  static Future<void> _showMatabRecipientPicker(
    BuildContext context, {
    required List<StaffContact> matabList,
    required String message,
    String? imagePath,
    VoidCallback? onContactUpdated,
  }) async {
    List<StaffContact> currentList = List<StaffContact>.from(matabList);

    await HopalBottomSheet.show(
      context: context,
      title: 'בחירת מט"ב להתייעצות (WhatsApp)',
      child: StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final active = currentList.where((c) => c.isOnDuty).firstOrNull ?? currentList.first;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'בחר את הרופא או הפראמדיק התורן לשליחת הפנייה (או לחץ על סמל התורנות להחלפת תורן פעיל):',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: AppTheme.spacing16),
              HopalButton(
                label: 'שלח לתורן הפעיל: ${active.displayLabel}',
                icon: LucideIcons.messageCircle,
                onPressed: () async {
                  Navigator.pop(sheetCtx);
                  await _launchWhatsAppForPhone(context, active.phone, message, imagePath);
                },
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                'כל צוות המט"ב בגדוד:',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...currentList.map((contact) {
                final isRoleDoctor = contact.role == 'רופא';
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
                      backgroundColor: isRoleDoctor
                          ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                          : AppTheme.infoBlue.withValues(alpha: 0.2),
                      child: Icon(
                        isRoleDoctor ? LucideIcons.stethoscope : LucideIcons.heartPulse,
                        size: 16,
                        color: isRoleDoctor ? AppTheme.primaryGreen : AppTheme.infoBlue,
                      ),
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
                                BattalionStaffService.groupMatab,
                              );
                              final refreshed = await BattalionStaffService.loadGroup(
                                BattalionStaffService.groupMatab,
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
                            await _launchWhatsAppForPhone(context, contact.phone, message, imagePath);
                          },
                        ),
                      ],
                    ),
                    onTap: () async {
                      Navigator.pop(sheetCtx);
                      await _launchWhatsAppForPhone(context, contact.phone, message, imagePath);
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
                      showMatabSettingsSheet(context, onSaved: onContactUpdated);
                    },
                    icon: Icon(LucideIcons.settings, size: 15, color: AppTheme.textSecondary),
                    label: Text('ניהול רשימת מט"ב', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetCtx);
                      await _shareSafely(message, imagePath);
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

  static void _showAddFirstMatabPrompt(
    BuildContext context,
    String message,
    String? imagePath, {
    VoidCallback? onContactUpdated,
  }) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'רופא';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.backgroundSecondary,
          title: Row(
            children: [
              Icon(LucideIcons.stethoscope, color: AppTheme.primaryGreen),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: Text(
                  'הגדרת מט"ב (רופא / פראמדיק)',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
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
                  'הזן את פרטי המט"ב התורן (רופא או פראמדיק). ניתן להוסיף רופאים ופראמדיקים נוספים בתורנות דרך מסך ההגדרות:',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: AppTheme.spacing12),
                Row(
                  children: BattalionStaffService.matabRoles.map((role) {
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
                  hint: selectedRole == 'רופא' ? 'שם הרופא (לדוגמה: ד"ר כהן)' : 'שם הפראמדיק (לדוגמה: יונתן)',
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
                Navigator.pop(ctx);
                await _shareSafely(message, imagePath);
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
                  HopalFeedback.showError(ctx, 'נא להזין מספר טלפון תקין');
                  return;
                }
                Navigator.pop(ctx);
                await BattalionStaffService.upsertContact(
                  StaffContact(
                    id: const Uuid().v4(),
                    name: nameController.text.trim(),
                    phone: phone,
                    role: selectedRole,
                    group: BattalionStaffService.groupMatab,
                    isOnDuty: true,
                  ),
                );
                onContactUpdated?.call();
                if (context.mounted) {
                  await _launchWhatsAppForPhone(context, phone, message, imagePath);
                }
              },
              child: const Text('שמור ופתח ב-WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens a full management sheet for Matab staff (רופאים ופראמדיקים בתורנות).
  static Future<void> showMatabSettingsSheet(
    BuildContext context, {
    VoidCallback? onSaved,
  }) async {
    List<StaffContact> contacts = await BattalionStaffService.loadGroup(BattalionStaffService.groupMatab);
    if (!context.mounted) return;

    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'רופא';
    bool markOnDuty = contacts.isEmpty;
    String? editingId;

    await HopalBottomSheet.show(
      context: context,
      title: 'סגל מט"ב בתורנות (רופאים ופראמדיקים)',
      child: StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          Future<void> reload() async {
            final updated = await BattalionStaffService.loadGroup(BattalionStaffService.groupMatab);
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
                  'הגדר את צוות המט"ב של הגדוד (רופאים ופראמדיקים שעושים תורנות). סמן מי נמצא כעת בתורנות כדי שפניות ודוחות יופנו אליו במהירות.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: AppTheme.spacing16),
                if (contacts.isNotEmpty) ...[
                  Text(
                    'אנשי מט"ב רשומים (${contacts.length}):',
                    style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  ...contacts.map((c) {
                    final isDoc = c.role == 'רופא';
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
                            backgroundColor: isDoc
                                ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                                : AppTheme.infoBlue.withValues(alpha: 0.2),
                            child: Icon(
                              isDoc ? LucideIcons.stethoscope : LucideIcons.heartPulse,
                              size: 16,
                              color: isDoc ? AppTheme.primaryGreen : AppTheme.infoBlue,
                            ),
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
                                await BattalionStaffService.setOnDuty(c.id, BattalionStaffService.groupMatab);
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
                  editingId == null ? 'הוספת איש מט"ב חדש (רופא / פראמדיק):' : 'עריכת איש מט"ב:',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Row(
                  children: BattalionStaffService.matabRoles.map((role) {
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
                  hint: selectedRole == 'רופא' ? 'שם הרופא (לדוגמה: ד"ר כהן)' : 'שם הפראמדיק (לדוגמה: עמית)',
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
                    'סמן כמט"ב בתורנות פעילה כעת 🟢',
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
                        label: editingId == null ? 'הוסף לצוות המט"ב' : 'שמור שינויים',
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
                              group: BattalionStaffService.groupMatab,
                              isOnDuty: markOnDuty || contacts.isEmpty,
                            ),
                          );
                          nameController.clear();
                          phoneController.clear();
                          editingId = null;
                          markOnDuty = false;
                          await reload();
                          if (context.mounted) {
                            HopalFeedback.showSuccess(context, 'סגל המט"ב עודכן בהצלחה');
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

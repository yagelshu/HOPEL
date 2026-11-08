import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chopel_app/core/utils/image_data_uri_helper.dart';
import 'package:chopel_app/models/medical_case.dart';
import 'package:chopel_app/models/soldier.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:chopel_app/theme/components/hopal_text_field.dart';

/// Shared helper to consult the battalion physician (רופא גדודי) over WhatsApp
/// using the saved doctor contact, consistent across Dashboard & Case Detail screens.
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
    final platoonPart = (soldier?.platoon != null && soldier!.platoon!.isNotEmpty)
        ? ' | מחלקה ${soldier.platoon}'
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
    buffer.writeln('\nאשמח להנחיות רופא.');
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

    final prefs = await SharedPreferences.getInstance();
    final doctorPhone = prefs.getString(prefDoctorPhoneKey);

    if (doctorPhone != null && doctorPhone.trim().isNotEmpty) {
      final cleanPhone = formatPhoneForWhatsApp(doctorPhone);
      if (cleanPhone.isNotEmpty) {
        final waUrl = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
        if (await canLaunchUrl(waUrl)) {
          await launchUrl(waUrl, mode: LaunchMode.externalApplication);
          return;
        }
      }
    }

    if (!context.mounted) return;
    _showDoctorPhonePromptOrShare(context, message, medicalCase.imagePath);
  }

  static void _showDoctorPhonePromptOrShare(
    BuildContext context,
    String message,
    String? imagePath,
  ) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundSecondary,
        title: Row(
          children: [
            Icon(LucideIcons.stethoscope, color: AppTheme.primaryGreen),
            const SizedBox(width: AppTheme.spacing8),
            Expanded(
              child: Text(
                'התייעצות עם רופא הגדוד',
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
                'טרם הוגדר מספר טלפון עבור רופא הגדוד.\nהזן את מספרו לפתיחת WhatsApp ישיר (יישמר להבא), או שתף דרך אפליקציה אחרת:',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: AppTheme.spacing16),
              HopalTextField(
                controller: nameController,
                hint: 'שם הרופא (אופציונלי, לדוגמה: ד"ר כהן)',
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
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(prefDoctorPhoneKey, phone);
              if (nameController.text.trim().isNotEmpty) {
                await prefs.setString(prefDoctorNameKey, nameController.text.trim());
              }
              final cleanPhone = formatPhoneForWhatsApp(phone);
              final waUrl = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
              if (await canLaunchUrl(waUrl)) {
                await launchUrl(waUrl, mode: LaunchMode.externalApplication);
              } else if (context.mounted) {
                await _shareSafely(message, imagePath);
              }
            },
            child: const Text('שמור ופתח ב-WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}


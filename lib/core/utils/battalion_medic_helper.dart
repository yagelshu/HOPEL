import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_bottom_sheet.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:chopel_app/theme/components/hopal_text_field.dart';

class BattalionMedicHelper {
  static const String prefNameKey = 'hogad_name';
  static const String prefPhoneKey = 'hogad_phone_number';

  static Future<(String name, String phone)> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      prefs.getString(prefNameKey) ?? '',
      prefs.getString(prefPhoneKey) ?? '',
    );
  }

  static Future<void> save({required String name, required String phone}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefNameKey, name.trim());
    await prefs.setString(prefPhoneKey, phone.trim());
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
      await Share.share(message);
    }
  }

  /// Sends [message] directly to the saved חוג"ד WhatsApp chat, or prompts once to save their number.
  static Future<void> sendReportToHogad(
    BuildContext context,
    String message, {
    VoidCallback? onContactUpdated,
  }) async {
    final (_, savedPhone) = await loadSaved();
    if (savedPhone.trim().isNotEmpty) {
      if (!context.mounted) return;
      await _openWhatsAppWithPhone(context, savedPhone, message);
      return;
    }

    if (!context.mounted) return;
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.backgroundSecondary,
        title: Row(
          children: [
            Icon(LucideIcons.messageCircle, color: AppTheme.primaryGreen, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'הגדרת מספר חוג"ד',
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
                'הזן פעם אחת את מספר הטלפון של החוג"ד כדי שכל דיווחי המצבת והציוד ייפתחו ישירות בצ\'אט שלו ב-WhatsApp:',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: AppTheme.spacing16),
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
              await Share.share(message);
            },
            child: Text('שיתוף כללי', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final phone = phoneController.text.trim();
              if (phone.replaceAll(RegExp(r'\D'), '').length < 9) {
                HopalFeedback.showError(dialogCtx, 'נא להזין מספר טלפון תקין של החוג"ד');
                return;
              }
              await save(name: nameController.text, phone: phone);
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
    );
  }

  /// Opens a clean settings sheet to view/update the חוג"ד name & phone number.
  static Future<void> showSettingsSheet(
    BuildContext context, {
    VoidCallback? onSaved,
  }) async {
    final (currentName, currentPhone) = await loadSaved();
    if (!context.mounted) return;

    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone);

    await HopalBottomSheet.show(
      context: context,
      title: 'פרטי חוג"ד (דיווחי WhatsApp)',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'מספר זה ישמש לפתיחת שיחת WhatsApp ישירה עם החוג"ד בעת שליחת מצבת חובשים במוצב או דרישת השלמת חוסרי ציוד.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: AppTheme.spacing16),
          HopalTextField(
            controller: nameController,
            hint: 'שם החוג"ד (לדוגמה: רס"ל דניאל)',
            icon: LucideIcons.user,
          ),
          const SizedBox(height: AppTheme.spacing12),
          HopalTextField(
            controller: phoneController,
            hint: 'מספר טלפון ל-WhatsApp (למשל: 0501234567)',
            icon: LucideIcons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppTheme.spacing24),
          HopalButton(
            label: 'שמור פרטי חוג"ד',
            icon: LucideIcons.check,
            onPressed: () async {
              await save(name: nameController.text, phone: phoneController.text);
              onSaved?.call();
              if (context.mounted) {
                Navigator.pop(context);
                HopalFeedback.showSuccess(context, 'פרטי החוג"ד נשמרו בהצלחה');
              }
            },
          ),
          const SizedBox(height: AppTheme.spacing16),
        ],
      ),
    );
  }
}

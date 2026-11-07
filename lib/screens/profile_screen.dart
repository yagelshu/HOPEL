import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_list_tile.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:chopel_app/theme/components/hopal_bottom_sheet.dart';
import 'package:chopel_app/features/auth/login_screen.dart';
import 'package:chopel_app/features/auth/update_password_screen.dart';
import 'package:chopel_app/features/onboarding/unit_selection_screen.dart';
import 'package:chopel_app/features/dashboard/providers.dart';
import 'package:chopel_app/core/network/sync_engine.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:chopel_app/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chopel_app/core/database/database_service.dart';
import 'package:chopel_app/features/profile/deployment_summary_screen.dart';
import 'package:chopel_app/screens/user_manual_screen.dart';
import 'package:chopel_app/features/profile/soldiers_management_screen.dart';
import 'package:chopel_app/core/database/draft_service.dart';
import 'package:chopel_app/features/medical_cases/providers.dart';
import 'package:chopel_app/features/equipment/providers.dart';
import 'package:chopel_app/theme/components/hopal_text_field.dart';
import 'package:chopel_app/core/utils/app_constants.dart';
import 'package:chopel_app/core/utils/app_error_helper.dart';
import 'package:chopel_app/core/utils/battalion_medic_helper.dart';
import 'package:chopel_app/core/utils/web_reload.dart';
import 'package:chopel_app/core/services/standby_medics_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final String _syncTime = '15 דקות';
  bool _biometricsEnabled = false;
  bool _canCheckBiometrics = false;
  String _doctorName = '';
  String _doctorPhone = '';
  String _hogadName = '';
  String _hogadPhone = '';

  @override
  void initState() {
    super.initState();
    _loadBiometricSettings();
    _loadDoctorSettings();
  }

  Future<void> _loadDoctorSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final (hogadName, hogadPhone) = await BattalionMedicHelper.loadSaved();
    if (mounted) {
      setState(() {
        _doctorName = prefs.getString('doctor_name') ?? '';
        _doctorPhone = prefs.getString('doctor_phone_number') ?? '';
        _hogadName = hogadName;
        _hogadPhone = hogadPhone;
      });
    }
  }

  Future<void> _loadBiometricSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final canCheck = await AuthService().canUseBiometrics();
    if (mounted) {
      setState(() {
        _canCheckBiometrics = canCheck;
        _biometricsEnabled = prefs.getBool('use_biometrics') ?? false;
      });
    }
  }

  Future<void> _toggleBiometrics() async {
    if (_biometricsEnabled) {
      await AuthService().disableBiometrics();
      if (!mounted) return;
      setState(() => _biometricsEnabled = false);
      HopalFeedback.showSuccess(context, 'אבטחה ביומטרית כובתה');
    } else {
      final error = await AuthService().enableBiometrics();
      if (!mounted) return;
      if (error == null) {
        setState(() {
          _biometricsEnabled = true;
          _canCheckBiometrics = true;
        });
        HopalFeedback.showSuccess(context, 'אבטחה ביומטרית הופעלה בהצלחה');
      } else {
        HopalFeedback.showError(context, error);
      }
    }
  }

  void _showEditUnitAndDeploymentSheet(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) return;

    final unitController = TextEditingController(text: user.unitName ?? '');
    final depController = TextEditingController(text: user.activeDeploymentName ?? '');
    bool isSaving = false;

    HopalBottomSheet.show(
      context: context,
      title: 'פרטי פלוגה ותעסוקה',
      child: StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'עדכן את שם הפלוגה או את שם התעסוקה הנוכחית. השינויים יתעדכנו עבור כלל החובשים בפלוגה.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: AppTheme.spacing16),
              if (user.unitId != null) ...[
                Text(
                  'שם הפלוגה',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                HopalTextField(
                  controller: unitController,
                  hint: 'לדוגמה: פלוגה ג\'',
                  icon: LucideIcons.flag,
                ),
                const SizedBox(height: AppTheme.spacing12),
              ],
              if (user.activeDeploymentId != null) ...[
                Text(
                  'שם התעסוקה הפעילה',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                HopalTextField(
                  controller: depController,
                  hint: 'לדוגמה: קו חברון / אימון צפון',
                  icon: LucideIcons.mapPin,
                ),
                const SizedBox(height: AppTheme.spacing24),
              ],
              HopalButton(
                label: 'שמור שינויים',
                icon: LucideIcons.check,
                isLoading: isSaving,
                onPressed: () async {
                  final newUnitName = unitController.text.trim();
                  final newDepName = depController.text.trim();

                  if (user.unitId != null && newUnitName.isEmpty) {
                    HopalFeedback.showError(context, 'נא להזין שם לפלוגה');
                    return;
                  }
                  if (user.activeDeploymentId != null && newDepName.isEmpty) {
                    HopalFeedback.showError(context, 'נא להזין שם לתעסוקה');
                    return;
                  }

                  setSheetState(() => isSaving = true);
                  try {
                    if (user.unitId != null && newUnitName != user.unitName) {
                      await Supabase.instance.client
                          .from('units')
                          .update({'name': newUnitName})
                          .eq('id', user.unitId!);
                    }
                    if (user.activeDeploymentId != null && newDepName != user.activeDeploymentName) {
                      await Supabase.instance.client
                          .from('deployments')
                          .update({'name': newDepName})
                          .eq('id', user.activeDeploymentId!);
                    }

                    AuthService().updateUnitAndDeploymentNames(
                      unitName: user.unitId != null ? newUnitName : null,
                      deploymentName: user.activeDeploymentId != null ? newDepName : null,
                    );
                    ref.invalidate(dashboardMetricsProvider);

                    if (!mounted) return;
                    setState(() {});
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                    HopalFeedback.showSuccess(context, 'פרטי הפלוגה והתעסוקה עודכנו בהצלחה');
                  } catch (e) {
                    if (sheetContext.mounted) {
                      setSheetState(() => isSaving = false);
                    }
                    if (mounted) {
                      HopalFeedback.showError(
                        this.context,
                        AppErrorHelper.toHebrew(e, fallback: 'שגיאה בעדכון הפרטים מול השרת.'),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: AppTheme.spacing16),
            ],
          );
        },
      ),
    );
  }

  void _confirmSwitchUnit(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.backgroundSecondary,
        title: Text(
          'החלפת פלוגה',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'פעולה זו תנתק את המשתמש שלך מהפלוגה הנוכחית ותעביר אותך למסך בחירת פלוגה – להקמת סביבת פלוגה חדשה או להצטרפות לפלוגה קיימת באמצעות קוד.\n\nנתוני הפלוגה הנוכחית יישמרו בענן.',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.45),
        ),
        actions: [
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
              Navigator.pop(dialogContext);
              try {
                await AuthService().detachFromCurrentUnit();
                ref.invalidate(medicalCasesProvider);
                ref.invalidate(soldiersProvider);
                ref.invalidate(equipmentProvider);
                ref.invalidate(dashboardMetricsProvider);

                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  this.context,
                  MaterialPageRoute(builder: (_) => const UnitSelectionScreen()),
                  (route) => false,
                );
              } catch (e) {
                if (mounted) {
                  HopalFeedback.showError(
                    this.context,
                    AppErrorHelper.toHebrew(e, fallback: 'שגיאה במעבר פלוגה. נסה שוב.'),
                  );
                }
              }
            },
            child: const Text('המשך לבחירת פלוגה', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showThemeSettings(BuildContext context) {
    HopalBottomSheet.show(
      context: context,
      title: 'הגדרות תצוגה',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HopalListTile(
            title: const Text('ערכת נושא מבצעית (כהה)'),
            subtitle: const Text('מומלץ לפעילות שטח'),
            leadingIcon: LucideIcons.moon,
            onTap: () {
              Navigator.pop(context);
              if (ref.read(themeProvider) != ThemeMode.dark) {
                ref.read(themeProvider.notifier).toggleTheme();
              }
              HopalFeedback.showSuccess(context, 'ערכת נושא עודכנה לכהה');
            },
          ),
          const SizedBox(height: AppTheme.spacing8),
          HopalListTile(
            title: const Text('ערכת נושא בהירה'),
            subtitle: const Text('מומלץ לתנאי תאורה חזקה'),
            leadingIcon: LucideIcons.sun,
            onTap: () {
              Navigator.pop(context);
              if (ref.read(themeProvider) != ThemeMode.light) {
                ref.read(themeProvider.notifier).toggleTheme();
              }
              HopalFeedback.showSuccess(context, 'ערכת נושא עודכנה לבהירה');
            },
          ),
          const SizedBox(height: AppTheme.spacing24),
        ],
      ),
    );
  }

  void _showDoctorSettingsDialog(BuildContext context) {
    final nameController = TextEditingController(text: _doctorName);
    final phoneController = TextEditingController(text: _doctorPhone);

    HopalBottomSheet.show(
      context: context,
      title: 'הגדרת רופא גדודי (WhatsApp)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'הגדר את מספר הטלפון של רופא הגדוד. בלחיצה על "התייעצות רופא" בתיק רפואי, האפליקציה תפתח ישירות שיחת WhatsApp עם תמצית המקרה הרפואי.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: AppTheme.spacing16),
          HopalTextField(
            controller: nameController,
            hint: 'שם הרופא (לדוגמה: ד"ר כהן)',
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
            label: 'שמור פרטי רופא',
            icon: LucideIcons.check,
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final newName = nameController.text.trim();
              final newPhone = phoneController.text.trim();
              await prefs.setString('doctor_name', newName);
              await prefs.setString('doctor_phone_number', newPhone);
              if (context.mounted) {
                setState(() {
                  _doctorName = newName;
                  _doctorPhone = newPhone;
                });
                Navigator.pop(context);
                HopalFeedback.showSuccess(context, 'פרטי רופא הגדוד נשמרו בהצלחה');
              }
            },
          ),
          const SizedBox(height: AppTheme.spacing16),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getRealSyncMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncIso = prefs.getString('last_sync_timestamp');
    String formattedTime = 'טרם בוצע סנכרון בסשן זה';
    if (lastSyncIso != null) {
      final last = DateTime.tryParse(lastSyncIso);
      if (last != null) {
        final diff = DateTime.now().difference(last);
        if (diff.inMinutes < 1) {
          formattedTime = 'סונכרן לפני פחות מדקה';
        } else if (diff.inHours < 1) {
          formattedTime = 'סונכרן לפני ${diff.inMinutes} דקות';
        } else if (diff.inDays < 1) {
          formattedTime = 'סונכרן לפני ${diff.inHours} שעות';
        } else {
          formattedTime = 'סונכרן ב-${last.day}/${last.month} ${last.hour.toString().padLeft(2, '0')}:${last.minute.toString().padLeft(2, '0')}';
        }
      }
    }

    int pendingDrafts = 0;
    try {
      pendingDrafts = (await DraftService.getDrafts()).length;
    } catch (_) {}

    int pendingQueue = 0;
    try {
      final db = await DatabaseService().database;
      final q = await db.query('sync_queue');
      pendingQueue = q.length;
    } catch (_) {}

    final bool isOnline = AuthService().isAuthenticated;

    return {
      'formattedTime': formattedTime,
      'pendingDrafts': pendingDrafts,
      'pendingQueue': pendingQueue,
      'isOnline': isOnline,
    };
  }

  void _showSyncStatus(BuildContext context) {
    HopalBottomSheet.show(
      context: context,
      title: 'סטטוס סנכרון נתונים',
      child: FutureBuilder<Map<String, dynamic>>(
        future: _getRealSyncMetrics(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(AppTheme.spacing32),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final data = snapshot.data!;
          final isOnline = data['isOnline'] as bool;
          final formattedTime = data['formattedTime'] as String;
          final pendingDrafts = data['pendingDrafts'] as int;
          final pendingQueue = data['pendingQueue'] as int;

          return StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing12),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                          : AppTheme.warningAmber.withValues(alpha: 0.12),
                      borderRadius: AppTheme.radiusMd,
                      border: Border.all(
                        color: isOnline ? AppTheme.primaryGreen : AppTheme.warningAmber,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isOnline ? LucideIcons.cloudCheck : LucideIcons.cloudOff,
                          color: isOnline ? AppTheme.primaryGreen : AppTheme.warningAmber,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacing12),
                        Expanded(
                          child: Text(
                            isOnline
                                ? 'מחובר לשרת הענן (Supabase מקוון)'
                                : 'מצב לא מקוון – פעולות ושינויים נשמרים במכשיר',
                            style: TextStyle(
                              color: isOnline ? AppTheme.primaryGreen : AppTheme.warningAmber,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  HopalListTile(
                    title: const Text('תיקים ומקרי טיפול רפואי'),
                    subtitle: Text(pendingDrafts > 0
                        ? '$pendingDrafts פניות מקומיות ממתינות לסנכרון'
                        : '$formattedTime (הכל מסונכרן)'),
                    leadingIcon: LucideIcons.database,
                    trailing: Icon(
                      pendingDrafts > 0 ? LucideIcons.clock : LucideIcons.checkCircle2,
                      color: pendingDrafts > 0 ? AppTheme.warningAmber : AppTheme.successGreen,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  HopalListTile(
                    title: const Text('מלאי וציוד רפואי'),
                    subtitle: Text(pendingQueue > 0
                        ? '$pendingQueue עדכוני מלאי מקומיים ממתינים לסנכרון'
                        : '$formattedTime (מעודכן מול הענן)'),
                    leadingIcon: LucideIcons.briefcase,
                    trailing: Icon(
                      pendingQueue > 0 ? LucideIcons.clock : LucideIcons.checkCircle2,
                      color: pendingQueue > 0 ? AppTheme.warningAmber : AppTheme.successGreen,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing24),
                  HopalButton(
                    label: 'סנכרן נתונים כעת',
                    icon: LucideIcons.refreshCw,
                    onPressed: () async {
                      HopalFeedback.showInfo(context, 'מסנכרן נתונים מול הענן...');
                      try {
                        await SyncEngine().runSyncWorker();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('last_sync_timestamp', DateTime.now().toIso8601String());

                        ref.invalidate(medicalCasesProvider);
                        ref.invalidate(soldiersProvider);
                        ref.invalidate(equipmentProvider);

                        if (context.mounted) {
                          Navigator.pop(context);
                          HopalFeedback.showSuccess(context, 'הסנכרון הסתיים בהצלחה.');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          HopalFeedback.showError(context, AppErrorHelper.toHebrew(e, fallback: 'שגיאה בסנכרון הנתונים מול השרת.'));
                        }
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showFeedbackSheet(BuildContext context) {
    HopalBottomSheet.show(
      context: context,
      title: 'דיווח על תקלה / פידבק למפתח',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'אנחנו מעדכנים ומשפרים את HOPAL באופן רציף עבורכם. בחר את דרך יצירת הקשר הנוחה לך:',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: AppTheme.spacing16),
          HopalListTile(
            leadingIcon: LucideIcons.mail,
            title: const Text('פתיחה ישירה ב-Gmail (חלון דפדפן)'),
            subtitle: const Text('מומלץ למחשב – פותח ישירות טיוטה מול יגל'),
            onTap: () {
              Navigator.pop(context);
              final su = Uri.encodeComponent('פידבק / דיווח על תקלה באפליקציית חופ"ל');
              final url = 'https://mail.google.com/mail/?view=cm&fs=1&to=yagelshu@gmail.com&su=$su';
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
          ),
          const SizedBox(height: AppTheme.spacing8),
          HopalListTile(
            leadingIcon: LucideIcons.send,
            title: const Text('פתיחה באפליקציית מייל במכשיר'),
            subtitle: const Text('פתיחת Outlook / Apple Mail / ברירת מחדל'),
            onTap: () async {
              Navigator.pop(context);
              final emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'yagelshu@gmail.com',
                query: 'subject=${Uri.encodeComponent('פידבק על אפליקציית חופ"ל')}',
              );
              try {
                if (!await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication)) {
                  if (context.mounted) {
                    HopalFeedback.showError(context, 'לא נמצאה אפליקציית מייל ברירת מחדל במכשיר');
                  }
                }
              } catch (_) {
                if (context.mounted) {
                  HopalFeedback.showError(context, 'לא נמצאה אפליקציית מייל ברירת מחדל במכשיר');
                }
              }
            },
          ),
          const SizedBox(height: AppTheme.spacing8),
          HopalListTile(
            leadingIcon: LucideIcons.messageCircle,
            title: const Text('שליחת הודעה ב-WhatsApp'),
            subtitle: const Text('מענה ישיר ומיידי מהמפתח'),
            onTap: () {
              Navigator.pop(context);
              final text = Uri.encodeComponent('היי יגל, פידבק על אפליקציית חופ"ל: ');
              launchUrl(Uri.parse('https://wa.me/972545805546?text=$text'), mode: LaunchMode.externalApplication);
            },
          ),
          const SizedBox(height: AppTheme.spacing8),
          HopalListTile(
            leadingIcon: LucideIcons.copy,
            title: const Text('העתק כתובת אימייל'),
            subtitle: const Text('yagelshu@gmail.com'),
            onTap: () async {
              Navigator.pop(context);
              await Clipboard.setData(const ClipboardData(text: 'yagelshu@gmail.com'));
              if (context.mounted) {
                HopalFeedback.showSuccess(context, 'כתובת המייל הועתקה ללוח: yagelshu@gmail.com');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditPersonalDetailsSheet(BuildContext context) {
    final auth = AuthService();
    final isPreview = auth.isPreviewingAsCombatMedic;
    final nameController = TextEditingController(text: auth.effectiveUserName);
    final platoonController = TextEditingController(text: auth.effectiveUserPlatoon ?? '');
    final phoneController = TextEditingController(text: auth.effectiveUserPhone ?? '');
    bool isSaving = false;

    HopalBottomSheet.show(
      context: context,
      title: isPreview ? 'פרטי החובש בתצוגה' : 'עריכת הפרטים האישיים שלי',
      child: StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isPreview
                    ? 'עדכן את שם החובש, המחלקה ומספר הטלפון כפי שיוצגו במסך הבית, בכוננות ובווסט האישי שלו.'
                    : 'הפרטים שלך יוצגו בברכת הפתיחה במסך הבית, ברשימת החובשים במוצב ובווסט הציוד האישי שלך.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: AppTheme.spacing16),
              HopalTextField(
                controller: nameController,
                hint: 'שם מלא *',
                icon: LucideIcons.user,
              ),
              const SizedBox(height: AppTheme.spacing12),
              HopalTextField(
                controller: platoonController,
                hint: 'מחלקה / צוות (לדוגמה: מחלקה 1 / חפ"ק)',
                icon: LucideIcons.shield,
              ),
              const SizedBox(height: AppTheme.spacing12),
              HopalTextField(
                controller: phoneController,
                hint: 'מספר טלפון (לחיוג ו-WhatsApp)',
                icon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppTheme.spacing24),
              HopalButton(
                label: 'שמור פרטים אישיים',
                icon: LucideIcons.check,
                isLoading: isSaving,
                onPressed: () async {
                  final newName = nameController.text.trim();
                  final newPlatoon = platoonController.text.trim();
                  final newPhone = phoneController.text.trim();

                  if (newName.isEmpty) {
                    HopalFeedback.showError(context, 'נא להזין שם מלא');
                    return;
                  }

                  setSheetState(() => isSaving = true);
                  try {
                    if (isPreview) {
                      final previewProfile = auth.previewMedicProfile;
                      final previewId = previewProfile?['id'] ?? '';
                      final isManual = previewProfile?['is_manual'] == 'true';

                      auth.updatePreviewMedicDetails(
                        name: newName,
                        platoon: newPlatoon,
                        phoneNumber: newPhone,
                      );

                      if (previewId.isNotEmpty && !previewId.startsWith('demo_medic_')) {
                        if (isManual) {
                          final existingManual = await StandbyMedicsService.getManualMedics(auth.currentUser?.unitId);
                          final prev = existingManual.where((m) => m['id'] == previewId).firstOrNull;
                          await StandbyMedicsService.saveManualMedic(
                            auth.currentUser?.unitId,
                            {
                              'id': previewId,
                              'name': newName,
                              'role': 'COMBAT_MEDIC',
                              'phone_number': newPhone.isEmpty ? null : newPhone,
                              'platoon': newPlatoon.isEmpty ? null : newPlatoon,
                              'is_manual': true,
                              'standby': prev?['standby'] ?? true,
                            },
                          );
                        } else {
                          try {
                            await Supabase.instance.client.from('users').update({
                              'name': newName,
                              'phone_number': newPhone.isEmpty ? null : newPhone,
                              'platoon': newPlatoon.isEmpty ? null : newPlatoon,
                            }).eq('id', previewId);
                          } on PostgrestException catch (_) {
                            await Supabase.instance.client.from('users').update({
                              'name': newName,
                            }).eq('id', previewId);
                          }
                        }
                      }
                      ref.invalidate(dashboardMetricsProvider);
                    } else {
                      await auth.updatePersonalDetails(
                        name: newName,
                        phoneNumber: newPhone,
                        platoon: newPlatoon,
                      );
                      ref.invalidate(dashboardMetricsProvider);
                    }

                    if (mounted) setState(() {});
                    if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                    if (context.mounted) {
                      HopalFeedback.showSuccess(context, 'הפרטים האישיים נשמרו בהצלחה');
                    }
                  } catch (e) {
                    if (sheetCtx.mounted) setSheetState(() => isSaving = false);
                    if (context.mounted) {
                      HopalFeedback.showError(
                        context,
                        AppErrorHelper.toHebrew(e, fallback: 'שגיאה בשמירת הפרטים האישיים.'),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: AppTheme.spacing16),
            ],
          );
        },
      ),
    );
  }

  void _showCombatMedicPreviewSelector(BuildContext context) {
    final auth = AuthService();
    final selfId = auth.currentUser?.id;
    final allMedics = ref.read(dashboardMetricsProvider).asData?.value.activeMedics ?? const [];
    final platoonMedics = allMedics
        .where((m) => m['id'] != selfId && m['id']?.toString().startsWith('demo_medic_') != true)
        .toList();

    final customNameController = TextEditingController(
      text: auth.isPreviewingAsCombatMedic ? auth.effectiveUserName : '',
    );
    final customPlatoonController = TextEditingController(
      text: auth.isPreviewingAsCombatMedic ? (auth.effectiveUserPlatoon ?? '') : '',
    );

    HopalBottomSheet.show(
      context: context,
      title: 'תצוגת חובש – בחירת חובש',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'בחר חובש מהפלוגה (או הקלד שם חובש) כדי לראות את האפליקציה, מסך הבית ווסט הציוד האישי בדיוק מהעיניים שלו:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: AppTheme.spacing16),
            if (platoonMedics.isNotEmpty) ...[
              Text(
                'חובשים בפלוגה',
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...platoonMedics.map((m) {
                final mId = m['id'].toString();
                final mName = (m['name'] ?? 'חובש').toString();
                final mPlatoon = m['platoon']?.toString();
                final mPhone = m['phone_number']?.toString();
                final isSelected = auth.isPreviewingAsCombatMedic && auth.effectiveUserId == mId;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundSecondary,
                    borderRadius: AppTheme.radiusMd,
                    border: Border.all(
                      color: isSelected ? AppTheme.warningAmber : AppTheme.borderSubtle,
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                      child: Icon(LucideIcons.stethoscope, color: AppTheme.primaryGreen, size: 18),
                    ),
                    title: Text(
                      mName,
                      style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                    ),
                    subtitle: mPlatoon != null && mPlatoon.isNotEmpty
                        ? Text(mPlatoon, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))
                        : const Text('צפה במסך הבית ובווסט האישי שלו', style: TextStyle(fontSize: 12)),
                    trailing: Icon(LucideIcons.chevronLeft, color: AppTheme.textMuted, size: 18),
                    onTap: () {
                      auth.startCombatMedicPreview(
                        id: mId,
                        name: mName,
                        platoon: mPlatoon,
                        phone: mPhone,
                        isManual: m['is_manual'] == true,
                      );
                      ref.invalidate(dashboardMetricsProvider);
                      Navigator.pop(context); // close sheet
                      if (Navigator.canPop(this.context)) {
                        Navigator.pop(this.context); // return to main tabs as that medic
                      }
                    },
                  ),
                );
              }),
              const SizedBox(height: AppTheme.spacing12),
            ],
            Text(
              platoonMedics.isEmpty ? 'הזן שם חובש לתצוגה' : 'או תצוגה בשם מותאם אישית',
              style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            HopalTextField(
              controller: customNameController,
              hint: 'שם החובש (לדוגמה: עמית לוי)',
              icon: LucideIcons.user,
            ),
            const SizedBox(height: 8),
            HopalTextField(
              controller: customPlatoonController,
              hint: 'מחלקה (אופציונלי, לדוגמה: מחלקה 2)',
              icon: LucideIcons.shield,
            ),
            const SizedBox(height: AppTheme.spacing16),
            HopalButton(
              label: 'הפעל תצוגת חובש בשם זה',
              icon: LucideIcons.eye,
              onPressed: () {
                final customName = customNameController.text.trim().isEmpty
                    ? 'חובש לדוגמה'
                    : customNameController.text.trim();
                final customPlatoon = customPlatoonController.text.trim();
                final syntheticId = 'demo_medic_${customName.hashCode.abs()}';

                auth.startCombatMedicPreview(
                  id: syntheticId,
                  name: customName,
                  platoon: customPlatoon,
                  isManual: true,
                );
                ref.invalidate(dashboardMetricsProvider);
                Navigator.pop(context);
                if (Navigator.canPop(this.context)) {
                  Navigator.pop(this.context);
                }
              },
            ),
            if (auth.isPreviewingAsCombatMedic) ...[
              const SizedBox(height: AppTheme.spacing12),
              HopalButton(
                label: 'סיום תצוגת חובש וחזרה לחופ"ל',
                icon: LucideIcons.undo2,
                variant: HopalButtonVariant.secondary,
                onPressed: () {
                  auth.setCombatMedicPreview(false);
                  ref.invalidate(dashboardMetricsProvider);
                  Navigator.pop(context);
                },
              ),
            ],
            const SizedBox(height: AppTheme.spacing16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final currentThemeStr = isDarkMode ? 'מבצעית' : 'בהירה';

    return ValueListenableBuilder<int>(
      valueListenable: AuthService().previewRevisionNotifier,
      builder: (context, _, __) {
        final auth = AuthService();
        final isCompanyMedic = auth.isCompanyMedic;
        final isActualCompanyMedic = auth.isActualCompanyMedic;
        final isPreviewingAsMedic = auth.isPreviewingAsCombatMedic;
        final displayName = auth.effectiveUserName;
        final displayPlatoon = auth.effectiveUserPlatoon;
        final displayPhone = auth.effectiveUserPhone;

        return Scaffold(
          backgroundColor: AppTheme.backgroundPrimary,
          body: CustomScrollView(
            slivers: [
              const SliverAppBar(
                title: Text('הגדרות ופרופיל', style: TextStyle(fontWeight: FontWeight.bold)),
                floating: true,
                pinned: true,
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (isPreviewingAsMedic) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.warningAmber.withValues(alpha: 0.16),
                          borderRadius: AppTheme.radiusMd,
                          border: Border.all(color: AppTheme.warningAmber),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.eye, size: 18, color: AppTheme.warningAmber),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'תצוגת חובש: $displayName',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _showCombatMedicPreviewSelector(context),
                              child: Text(
                                'החלף חובש',
                                style: TextStyle(
                                  color: AppTheme.warningAmber,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: AppTheme.warningAmber,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                AuthService().setCombatMedicPreview(false);
                                ref.invalidate(dashboardMetricsProvider);
                              },
                              child: const Text('חזרה לחופ"ל', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                    ],
                    HopalCard(
                      padding: const EdgeInsets.all(AppTheme.spacing24),
                      onTap: () => _showEditPersonalDetailsSheet(context),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.primaryGreen),
                            ),
                            child: Icon(LucideIcons.user, size: 32, color: AppTheme.primaryGreen),
                          ),
                          const SizedBox(width: AppTheme.spacing24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        displayName,
                                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(LucideIcons.pencil, size: 16, color: AppTheme.primaryGreen),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.spacing4),
                                Text(
                                  [
                                    isCompanyMedic ? 'חופ"ל' : 'חובש קרבי',
                                    if (displayPlatoon != null && displayPlatoon.isNotEmpty) displayPlatoon,
                                  ].join(' • '),
                                  style: TextStyle(fontSize: 15, color: AppTheme.militaryOlive),
                                ),
                                if (displayPhone != null && displayPhone.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(displayPhone, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                ],
                                const SizedBox(height: AppTheme.spacing4),
                                Row(
                                  children: [
                                    Icon(LucideIcons.award, color: AppTheme.warningAmber, size: 16),
                                    const SizedBox(width: 4),
                                    Text('${user?.competencePoints ?? 0} נקודות כשירות', style: TextStyle(fontSize: 14, color: AppTheme.warningAmber, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.spacing4),
                                Wrap(
                                  spacing: AppTheme.spacing8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(user?.unitName ?? 'יחידה לא ידועה', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                                    if (isCompanyMedic && user?.unitJoinCode != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text('קוד: ${user!.unitJoinCode}', style: TextStyle(fontSize: 12, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                                if (user?.activeDeploymentName != null) ...[
                                  const SizedBox(height: AppTheme.spacing4),
                                  Row(
                                    children: [
                                      Icon(LucideIcons.mapPin, color: AppTheme.primaryGreen, size: 14),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'תעסוקה פעילה: ${user!.activeDeploymentName}',
                                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (isCompanyMedic && user?.unitJoinCode != null) ...[
                      const SizedBox(height: AppTheme.spacing16),
                      HopalButton(
                        label: 'הזמן חובשים לפלוגה',
                        icon: LucideIcons.userPlus,
                        variant: HopalButtonVariant.secondary,
                        onPressed: () async {
                          final message = 'היי! מוזמן להצטרף לסביבת הפלוגה שלנו באפליקציית HOPAL.\nקוד ההצטרפות שלנו הוא: *${user!.unitJoinCode}*';
                          await Share.share(message);
                        },
                      ),
                    ],

                    const SizedBox(height: AppTheme.spacing32),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                      child: Text('פרטים אישיים ופלוגה', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    HopalCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          HopalListTile(
                            title: const Text('עריכת הפרטים האישיים שלי'),
                            subtitle: Text(
                              [
                                displayName,
                                if (displayPlatoon != null && displayPlatoon.isNotEmpty) displayPlatoon,
                                if (displayPhone != null && displayPhone.isNotEmpty) displayPhone,
                              ].join(' • '),
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                            leadingIcon: LucideIcons.userPen,
                            onTap: () => _showEditPersonalDetailsSheet(context),
                          ),
                          if (isCompanyMedic) ...[
                            HopalListTile(
                              title: const Text('עריכת פרטי פלוגה ותעסוקה'),
                              subtitle: Text(
                                '${user?.unitName ?? 'ללא פלוגה'} • ${user?.activeDeploymentName ?? 'ללא תעסוקה פעילה'}',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                              ),
                              leadingIcon: LucideIcons.pencil,
                              onTap: () => _showEditUnitAndDeploymentSheet(context),
                            ),
                            HopalListTile(
                              title: const Text('ניהול חיילים בפלוגה'),
                              subtitle: const Text('עריכה ומחיקת חיילים מהמאגר'),
                              leadingIcon: LucideIcons.users,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SoldiersManagementScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                          HopalListTile(
                            title: const Text('החלפת פלוגה'),
                            subtitle: const Text('הקמת פלוגה חדשה או הצטרפות באמצעות קוד'),
                            leadingIcon: LucideIcons.arrowLeftRight,
                            onTap: () => _confirmSwitchUnit(context),
                          ),
                          if (isActualCompanyMedic)
                            HopalListTile(
                              title: const Text('תצוגת חובש (בחירת חובש ובדיקת הרשאות)'),
                              subtitle: Text(
                                isPreviewingAsMedic
                                    ? 'פעיל עבור: $displayName • לחץ להחלפת חובש או לסיום'
                                    : 'בחר חובש מהפלוגה או הזן שם כדי לראות את המסכים והווסט שלו',
                                style: TextStyle(
                                  color: isPreviewingAsMedic ? AppTheme.warningAmber : AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              leadingIcon: LucideIcons.eye,
                              trailing: Switch(
                                value: isPreviewingAsMedic,
                                onChanged: (val) {
                                  if (val) {
                                    _showCombatMedicPreviewSelector(context);
                                  } else {
                                    AuthService().setCombatMedicPreview(false);
                                    ref.invalidate(dashboardMetricsProvider);
                                  }
                                },
                                activeTrackColor: AppTheme.warningAmber,
                              ),
                              onTap: () => _showCombatMedicPreviewSelector(context),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacing32),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                      child: Text('מערכת וסנכרון', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    HopalCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          if (isCompanyMedic) ...[
                            HopalListTile(
                              title: const Text('חוג"ד הגדוד (דיווחי WhatsApp)'),
                              subtitle: Text(
                                _hogadPhone.isNotEmpty
                                    ? '${_hogadName.isNotEmpty ? '$_hogadName • ' : ''}$_hogadPhone'
                                    : 'טרם הוגדר מספר (לחץ להגדרה מהירה)',
                                style: TextStyle(
                                  color: _hogadPhone.isNotEmpty ? AppTheme.primaryGreen : AppTheme.warningAmber,
                                  fontSize: 13,
                                ),
                              ),
                              leadingIcon: LucideIcons.messageCircle,
                              onTap: () => BattalionMedicHelper.showSettingsSheet(
                                context,
                                onSaved: _loadDoctorSettings,
                              ),
                            ),
                            HopalListTile(
                              title: const Text('רופא הגדוד (התייעצות WhatsApp)'),
                              subtitle: Text(
                                _doctorPhone.isNotEmpty
                                    ? '${_doctorName.isNotEmpty ? '$_doctorName • ' : ''}$_doctorPhone'
                                    : 'טרם הוגדר מספר (לחץ להגדרה מהירה)',
                                style: TextStyle(
                                  color: _doctorPhone.isNotEmpty ? AppTheme.primaryGreen : AppTheme.warningAmber,
                                  fontSize: 13,
                                ),
                              ),
                              leadingIcon: LucideIcons.stethoscope,
                              onTap: () => _showDoctorSettingsDialog(context),
                            ),
                          ],
                          HopalListTile(
                            title: const Text('מצב סנכרון'),
                            subtitle: Text(_syncTime == 'כעת' ? 'סונכרן כעת' : 'מחובר לרשת (מקוון)'),
                            leadingIcon: LucideIcons.wifi,
                            onTap: () => _showSyncStatus(context),
                          ),
                          HopalListTile(
                            title: const Text('סנכרון טיוטות מקומיות (אופליין)'),
                            subtitle: const Text('שלח תיקים שנשמרו כשלא הייתה קליטה'),
                            leadingIcon: LucideIcons.cloudLightning,
                            onTap: () async {
                              final hasDrafts = await DraftService.hasDrafts();
                              if (!hasDrafts) {
                                if (context.mounted) HopalFeedback.showSuccess(context, 'אין טיוטות שממתינות לסנכרון');
                                return;
                              }
                              if (context.mounted) HopalFeedback.showSuccess(context, 'מסנכרן טיוטות מול השרת...');
                              final count = await DraftService.syncDrafts();
                              if (context.mounted) {
                                if (count > 0) {
                                  HopalFeedback.showSuccess(context, '$count טיוטות סונכרנו בהצלחה!');
                                  ref.read(medicalCasesProvider.notifier).refresh();
                                } else {
                                  HopalFeedback.showError(context, 'שגיאה בסנכרון. אנא ודא שיש חיבור אינטרנט תקין.');
                                }
                              }
                            },
                          ),
                          HopalListTile(
                            title: const Text('הגדרות תצוגה'),
                            subtitle: Text('ערכת נושא $currentThemeStr'),
                            leadingIcon: LucideIcons.monitor,
                            onTap: () => _showThemeSettings(context),
                          ),
                          HopalListTile(
                            title: const Text('אבטחה ביומטרית'),
                            subtitle: Text(
                              _biometricsEnabled
                                  ? 'זיהוי פנים / טביעת אצבע מופעל'
                                  : (_canCheckBiometrics
                                      ? 'לחץ להפעלת טביעת אצבע / זיהוי פנים'
                                      : 'לחץ להפעלה (מומלץ בדפדפן Chrome / Safari)'),
                              style: TextStyle(
                                color: _biometricsEnabled ? AppTheme.primaryGreen : AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            leadingIcon: LucideIcons.fingerprint,
                            trailing: Switch(
                              value: _biometricsEnabled,
                              onChanged: (_) => _toggleBiometrics(),
                              activeTrackColor: AppTheme.primaryGreen,
                            ),
                            onTap: _toggleBiometrics,
                          ),
                          HopalListTile(
                            title: const Text('שינוי סיסמה'),
                            subtitle: const Text('בחירת סיסמה חדשה לחשבון שלך'),
                            leadingIcon: LucideIcons.keyRound,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const UpdatePasswordScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacing32),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                      child: Text('תמיכה ואודות', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    HopalCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          HopalListTile(
                            title: const Text('מדריך למשתמש'),
                            leadingIcon: LucideIcons.helpCircle,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const UserManualScreen(),
                                ),
                              );
                            },
                          ),
                          HopalListTile(
                            title: const Text('דיווח על תקלה / פידבק'),
                            subtitle: const Text('Gmail • WhatsApp • העתקת מייל'),
                            leadingIcon: LucideIcons.messageSquare,
                            trailing: Icon(LucideIcons.chevronLeft, color: AppTheme.textSecondary, size: 18),
                            onTap: () => _showFeedbackSheet(context),
                          ),
                          HopalListTile(
                            title: const Text('אודות המערכת וגרסה'),
                            subtitle: const Text('גרסה ${AppConstants.fullVersionLabel} • לחץ לעדכון גרסה'),
                            leadingIcon: LucideIcons.info,
                            onTap: () {
                              HopalBottomSheet.show(
                                context: context,
                                title: 'אודות HOPAL',
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text('גרסת אפליקציה: ${AppConstants.fullVersionLabel}', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text(
                                      'האפליקציה מתעדכנת אוטומטית מהענן. לחיצה על הכפתור למטה תנקה את המטמון המקומי ותטען מיד את הגרסה החדשה ביותר מהשרת (גם בנייד וגם במחשב).',
                                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                                    ),
                                    const SizedBox(height: AppTheme.spacing24),
                                    HopalButton(
                                      label: 'עדכן ורענן אפליקציה כעת',
                                      icon: LucideIcons.refreshCw,
                                      onPressed: () async {
                                        final reloaded = await WebReload.forceUpdateAndReload();
                                        if (!reloaded && context.mounted) {
                                          Navigator.pop(context);
                                          HopalFeedback.showSuccess(context, 'האפליקציה מעודכנת לגרסה האחרונה');
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacing48),

                    if (isCompanyMedic) ...[
                      HopalButton(
                        label: 'סיום תעסוקה מבצעית',
                        icon: LucideIcons.flag,
                        variant: HopalButtonVariant.secondary,
                        isExpanded: true,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const DeploymentSummaryScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                    ],

                    HopalButton(
                      label: 'התנתקות מהמערכת',
                      icon: LucideIcons.logOut,
                      variant: HopalButtonVariant.destructive,
                      isExpanded: true,
                      onPressed: () {
                        AuthService().logout();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                    ),

                    const SizedBox(height: 120), // Bottom nav padding
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

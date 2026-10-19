import 'package:flutter/material.dart';
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
import 'package:chopel_app/features/learning/learning_content_viewer_screen.dart';
import 'package:chopel_app/core/network/sync_engine.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:chopel_app/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:chopel_app/core/database/database_service.dart';
import 'package:chopel_app/screens/main_layout_screen.dart';
import 'package:chopel_app/features/profile/deployment_summary_screen.dart';
import 'package:chopel_app/screens/user_manual_screen.dart';
import 'package:chopel_app/features/profile/soldiers_management_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:chopel_app/core/database/draft_service.dart';
import 'package:chopel_app/features/medical_cases/providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _syncTime = '15 דקות';
  bool _notificationsEnabled = true;
  bool _biometricsEnabled = false;
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricSettings();
  }

  Future<void> _loadBiometricSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _biometricsEnabled = false;
          _canCheckBiometrics = false;
        });
      }
      return;
    }
    final auth = LocalAuthentication();
    final canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();
    if (mounted) {
      setState(() {
        _biometricsEnabled = prefs.getBool('use_biometrics') ?? false;
        _canCheckBiometrics = canCheck;
      });
    }
  }

  Future<void> _toggleBiometrics() async {
    if (kIsWeb) {
      HopalFeedback.showInfo(context, 'אבטחה ביומטרית (טביעת אצבע / Face ID) נתמכת במכשירי מובייל בלבד. בדפדפן במחשב הגישה מוגנת בסיסמה.');
      return;
    }
    if (!_canCheckBiometrics) {
      HopalFeedback.showError(context, 'המכשיר שלך לא תומך בזיהוי ביומטרי');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final newValue = !_biometricsEnabled;
    await prefs.setBool('use_biometrics', newValue);
    setState(() {
      _biometricsEnabled = newValue;
    });
    HopalFeedback.showSuccess(context, newValue ? 'אבטחה ביומטרית הופעלה' : 'אבטחה ביומטרית כובתה');
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

                        if (context.mounted) {
                          Navigator.pop(context);
                          HopalFeedback.showSuccess(context, 'הסנכרון הסתיים בהצלחה.');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          HopalFeedback.showError(context, 'שגיאה בסנכרון: $e');
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
                    HopalFeedback.showError(context, 'לא נמצאה אפליקציית מייל ברירת מחדל במחשב');
                  }
                }
              } catch (_) {
                if (context.mounted) {
                  HopalFeedback.showError(context, 'לא נמצאה אפליקציית מייל ברירת מחדל במחשב');
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

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final currentThemeStr = isDarkMode ? 'מבצעית' : 'בהירה';

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
                HopalCard(
            padding: const EdgeInsets.all(AppTheme.spacing24),
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
                      Text(user?.name ?? 'משתמש', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(user?.role == 'COMPANY_MEDIC' ? 'חופ"ל' : 'חובש קרבי', style: TextStyle(fontSize: 16, color: AppTheme.militaryOlive)),
                      const SizedBox(height: AppTheme.spacing4),
                      Row(
                        children: [
                          Icon(LucideIcons.award, color: AppTheme.warningAmber, size: 16),
                          const SizedBox(width: 4),
                          Text('${user?.competencePoints ?? 0} נקודות כשירות', style: TextStyle(fontSize: 14, color: AppTheme.warningAmber, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Row(
                        children: [
                          Text(user?.unitName ?? 'יחידה לא ידועה', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                          if (user?.unitJoinCode != null) ...[
                            const SizedBox(width: AppTheme.spacing8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('קוד: ${user!.unitJoinCode}', style: TextStyle(fontSize: 12, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (user?.unitJoinCode != null) ...[
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
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
            child: Text('מערכת וסנכרון', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          ),
          const SizedBox(height: AppTheme.spacing12),
          HopalCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
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
                  title: const Text('ניהול התראות'),
                  subtitle: Text(_notificationsEnabled ? 'התראות דחיפה מופעלות' : 'התראות דחיפה כבויות'),
                  leadingIcon: _notificationsEnabled ? LucideIcons.bellRing : LucideIcons.bellOff,
                  onTap: () {
                    setState(() => _notificationsEnabled = !_notificationsEnabled);
                    HopalFeedback.showSuccess(context, 'הגדרות התראות נשמרו');
                  },
                ),
                HopalListTile(
                  title: const Text('אבטחה ביומטרית'),
                  subtitle: Text(
                    kIsWeb 
                        ? 'פעיל במכשירי מובייל (Android / iOS) בלבד'
                        : (_canCheckBiometrics
                            ? (_biometricsEnabled ? 'זיהוי פנים/אצבע מופעל' : 'לחץ להפעלה')
                            : 'לא נתמך במכשיר זה'),
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  leadingIcon: LucideIcons.fingerprint,
                  trailing: kIsWeb
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundTertiary,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Text('מובייל בלבד', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        )
                      : Switch(
                          value: _biometricsEnabled && _canCheckBiometrics,
                          onChanged: _canCheckBiometrics ? (val) => _toggleBiometrics() : null,
                          activeColor: AppTheme.primaryGreen,
                        ),
                  onTap: _toggleBiometrics,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppTheme.spacing32),
          
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
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
                  subtitle: const Text('גרסה 1.2.0 • לחץ לבדיקת עדכונים'),
                  leadingIcon: LucideIcons.info,
                  onTap: () {
                    HopalBottomSheet.show(
                      context: context,
                      title: 'אודות HOPAL',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('גרסת אפליקציה: 1.2.0 (Build 50)', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            'האפליקציה מתעדכנת ברציף. במידה ואתה עובד מהדפדפן (Web/PWA) ולא רואה את השינויים האחרונים, מומלץ לבצע רענון מאולץ (Ctrl + F5 או Shift + טען מחדש) כדי לפנות את זיכרון המטמון.',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                          ),
                          const SizedBox(height: AppTheme.spacing24),
                          HopalButton(
                            label: 'רענן אפליקציה מחדש',
                            icon: LucideIcons.refreshCw,
                            onPressed: () {
                              Navigator.pop(context);
                              HopalFeedback.showInfo(context, 'לרענון נקי של המטמון ועדכון מיידי: לחץ Ctrl + F5 במקלדת');
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
  }
}

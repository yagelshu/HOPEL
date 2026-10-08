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
    final auth = LocalAuthentication();
    final canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();
    setState(() {
      _biometricsEnabled = prefs.getBool('use_biometrics') ?? false;
      _canCheckBiometrics = canCheck;
    });
  }

  Future<void> _toggleBiometrics() async {
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

  void _showSyncStatus(BuildContext context) {
    HopalBottomSheet.show(
      context: context,
      title: 'סטטוס סנכרון',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HopalListTile(
                title: Text('סנכרון נתונים רפואיים'),
                subtitle: Text('עודכן לפני 2 דקות'),
                leadingIcon: LucideIcons.database,
                trailing: Icon(LucideIcons.checkCircle2, color: AppTheme.successGreen),
              ),
              const SizedBox(height: AppTheme.spacing8),
              HopalListTile(
                title: const Text('סנכרון מלאי ציוד'),
                subtitle: Text(_syncTime == 'כעת' ? 'עודכן כעת' : 'עודכן לפני $_syncTime'),
                leadingIcon: LucideIcons.briefcase,
                trailing: Icon(LucideIcons.checkCircle2, color: AppTheme.successGreen),
              ),
              const SizedBox(height: AppTheme.spacing24),
              HopalButton(
                label: 'סנכרן כעת',
                icon: LucideIcons.refreshCw,
                onPressed: () async {
                  HopalFeedback.showInfo(context, 'מסנכרן נתונים מול הענן...');
                  await SyncEngine().runSyncWorker();
                  if (context.mounted) {
                    setModalState(() {});
                    setState(() => _syncTime = 'כעת');
                    Navigator.pop(context);
                    HopalFeedback.showSuccess(context, 'סנכרון הסתיים בהצלחה.');
                  }
                },
              ),
            ],
          );
        }
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
                  subtitle: Text(_biometricsEnabled ? 'זיהוי פנים/אצבע מופעל' : 'לחץ להפעלה'),
                  leadingIcon: LucideIcons.fingerprint,
                  trailing: Switch(
                    value: _biometricsEnabled,
                    onChanged: (val) => _toggleBiometrics(),
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
                  subtitle: const Text('שלח אימייל ישירות למפתח'),
                  leadingIcon: LucideIcons.messageSquare,
                  onTap: () async {
                    final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: 'yagelshu@gmail.com',
                      query: 'subject=פידבק על אפליקציית חופ"ל',
                    );
                    if (!await launchUrl(emailLaunchUri)) {
                      if (context.mounted) {
                        HopalFeedback.showError(context, 'לא הצלחנו לפתוח את אפליקציית המייל');
                      }
                    }
                  },
                ),
                HopalListTile(
                  title: const Text('אודות המערכת'),
                  subtitle: const Text('גרסה 1.0.0 (Build 42)'),
                  leadingIcon: LucideIcons.info,
                  onTap: () {},
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

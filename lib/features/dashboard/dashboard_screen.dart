import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/features/dashboard/providers.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_status_badge.dart';
import 'package:chopel_app/theme/components/hopal_timeline.dart';
import 'package:chopel_app/theme/components/hopal_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chopel_app/theme/components/hopal_shimmer.dart';

import 'package:chopel_app/models/soldier.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:chopel_app/core/network/sync_engine.dart';
import 'package:chopel_app/features/medical_cases/medical_case_detail_screen.dart';
import 'package:chopel_app/features/medical_cases/providers.dart';
import 'package:chopel_app/features/medical_cases/medical_case_create_screen.dart';
import 'package:chopel_app/features/equipment/equipment_list_screen.dart';
import 'package:chopel_app/screens/profile_screen.dart';
import 'package:chopel_app/features/profile/soldiers_management_screen.dart';
import 'package:chopel_app/features/learning/trivia_screen.dart';
import 'package:chopel_app/features/onboarding/walkthrough_dialog.dart';
import 'package:chopel_app/core/database/draft_service.dart';
import 'package:chopel_app/core/services/standby_medics_service.dart';
import 'package:chopel_app/core/utils/app_error_helper.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final bool animateEntrance;
  const DashboardScreen({super.key, this.animateEntrance = false});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _headerFade;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;
  late List<Animation<double>> _cardFades;
  late Animation<double> _timelineFade;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    final curve = CurvedAnimation(parent: _entranceController, curve: const Cubic(0.0, 0.0, 0.2, 1.0));

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: curve, curve: const Interval(0.0, 0.3)));
    _heroFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: curve, curve: const Interval(0.2, 0.5)));
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: curve, curve: const Interval(0.2, 0.5)));

    _cardFades = List.generate(4, (i) {
      double start = 0.4 + (i * 0.1);
      return Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: curve, curve: Interval(start, (start + 0.3).clamp(0.0, 1.0))));
    });

    _timelineFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: curve, curve: const Interval(0.7, 1.0)));

    if (widget.animateEntrance) {
      _entranceController.forward();
    } else {
      _entranceController.value = 1.0;
    }

    _checkFirstTimeSetup();
    _autoSyncDrafts();
  }

  Future<void> _autoSyncDrafts() async {
    try {
      if (await DraftService.hasDrafts()) {
        final synced = await DraftService.syncDrafts();
        if (synced > 0 && mounted) {
          ref.read(medicalCasesProvider.notifier).refresh();
          ref.invalidate(dashboardMetricsProvider);
        }
      }
    } catch (_) {}
  }

  Future<void> _checkFirstTimeSetup() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding_v1') ?? false;

    if (!hasSeenOnboarding) {
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const WalkthroughDialog(),
      );
      await prefs.setBool('has_seen_onboarding_v1', true);
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Widget _animateWidget(Widget child, Animation<double> fade, [Animation<Offset>? slide]) {
    if (!widget.animateEntrance) return child;
    Widget animated = FadeTransition(opacity: fade, child: child);
    if (slide != null) animated = SlideTransition(position: slide, child: animated);
    return animated;
  }

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final user = AuthService().currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: metricsAsync.when(
          data: (metrics) {
            return RefreshIndicator(
              onRefresh: () async {
                return ref.refresh(dashboardMetricsProvider);
              },
              color: AppTheme.primaryGreen,
              backgroundColor: AppTheme.backgroundSecondary,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _animateWidget(_buildHeader(user?.name ?? 'חופ"ל', user), _headerFade),
                  ),
                  SliverToBoxAdapter(
                    child: ValueListenableBuilder<int>(
                      valueListenable: DraftService.draftsCountNotifier,
                      builder: (context, count, _) {
                        if (count == 0) return const SizedBox.shrink();
                        return _buildDraftsBanner(count);
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _animateWidget(_buildHero(metrics), _heroFade, _heroSlide),
                  ),
                  SliverToBoxAdapter(
                    child: _animateWidget(_buildPriorityActions(metrics), _cardFades[0]),
                  ),
                  SliverToBoxAdapter(
                    child: _animateWidget(_buildQuickActions(), _cardFades[1]),
                  ),
                  SliverToBoxAdapter(
                    child: _animateWidget(_buildOperationalStatus(metrics), _cardFades[2]),
                  ),
                  SliverToBoxAdapter(
                    child: _animateWidget(_buildDailyTimeline(metrics), _timelineFade),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)), // Bottom nav padding
                ],
              ),
            );
          },
          loading: () => ListView.builder(
            itemCount: 3,
            padding: const EdgeInsets.only(top: 40),
            itemBuilder: (context, index) => const HopalShimmerCard(height: 150),
          ),
          error: (err, stack) => const Center(child: Text('שגיאה בטעינת נתונים')),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, [User? user]) {
    final unitName = user?.unitName ?? 'פלוגה';
    final deploymentName = user?.activeDeploymentName ?? '';
    final roleLabel = AuthService().isCompanyMedic ? 'חופ"ל' : 'חובש קרבי';
    final subtitle = deploymentName.isNotEmpty
        ? '$roleLabel • $unitName ($deploymentName)'
        : '$roleLabel • $unitName';

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, AppTheme.spacing32, AppTheme.spacing16, AppTheme.spacing24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Transform.scale(
                    scale: 1.05,
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(LucideIcons.shieldAlert, size: 48, color: AppTheme.primaryGreen),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'שלום $name',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        subtitle,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderSubtle, width: 2),
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.backgroundSecondary,
                child: Icon(LucideIcons.user, size: 20, color: AppTheme.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(DashboardMetrics metrics) {
    final int criticalAlerts = metrics.requiresAttentionCases + metrics.missingEquipment;
    final bool isReady = criticalAlerts == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      child: HopalCard(
        backgroundColor: isReady ? AppTheme.primaryGreen.withValues(alpha: 0.15) : AppTheme.warningAmber.withValues(alpha: 0.1),
        borderColor: isReady ? AppTheme.primaryGreen.withValues(alpha: 0.3) : AppTheme.warningAmber.withValues(alpha: 0.3),
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(isReady ? LucideIcons.shieldCheck : LucideIcons.shieldAlert, color: isReady ? AppTheme.successGreen : AppTheme.warningAmber, size: 20),
                      const SizedBox(width: AppTheme.spacing8),
                      Text('כשירות מבצעית', style: TextStyle(color: isReady ? AppTheme.successGreen : AppTheme.warningAmber, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      const Spacer(),
                      if (!isReady)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.warningAmber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('$criticalAlerts חריגים', style: TextStyle(color: AppTheme.warningAmber, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  Text(isReady ? 'הכל תקין' : 'נדרש טיפול', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, height: 1.0, letterSpacing: -0.5)),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    isReady ? 'הפלוגה ערוכה לפעילות. הציוד תקין ואין חריגים.' : 'ישנם $criticalAlerts נושאים פתוחים הדורשים את תשומת לבך במיידי.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftsBanner(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, 0, AppTheme.spacing16, AppTheme.spacing16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing12),
        decoration: BoxDecoration(
          color: AppTheme.warningAmber.withValues(alpha: 0.15),
          borderRadius: AppTheme.radiusMd,
          border: Border.all(color: AppTheme.warningAmber.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.cloudOff, color: AppTheme.warningAmber, size: 22),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ישנן $count פניות שמורות בטלפון',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 14),
                  ),
                  Text(
                    'נשמרו ללא קליטה וממתינות לסנכרון',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningAmber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () async {
                final synced = await DraftService.syncDrafts();
                if (mounted) {
                  if (synced > 0) {
                    HopalFeedback.showSuccess(context, 'סונכרנו $synced פניות בהצלחה!');
                    ref.read(medicalCasesProvider.notifier).refresh();
                    ref.invalidate(dashboardMetricsProvider);
                  } else {
                    HopalFeedback.showError(context, 'לא ניתן לסנכרן כעת, ודא שיש קליטה זמינה');
                  }
                }
              },
              child: const Text('סנכרן כעת', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityActions(DashboardMetrics metrics) {
    final activeCasesList = ref.watch(medicalCasesProvider).maybeWhen(
      data: (cases) => cases.where((c) => c.status == 'REQUIRES_ATTENTION').toList(),
      orElse: () => null,
    );
    final activeCasesCount = activeCasesList?.length ?? metrics.requiresAttentionCases;

    final int criticalAlerts = activeCasesCount + metrics.missingEquipment;
    if (criticalAlerts == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, AppTheme.spacing32, AppTheme.spacing16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('דורש טיפול עכשיו', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary, fontSize: 18)),
              if (activeCasesCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.warningAmber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$activeCasesCount', style: TextStyle(color: AppTheme.warningAmber, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          if (metrics.missingEquipment > 0) ...[
            HopalCard(
              padding: EdgeInsets.zero,
              child: _buildActionItemRow(
                icon: LucideIcons.briefcase,
                title: 'חוסר ציוד',
                description: '${metrics.missingEquipment} פריטים חסרים בתיק',
                variant: HopalStatusBadgeVariant.warning,
                targetScreen: const EquipmentListScreen(),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],
          ref.watch(medicalCasesProvider).when(
            data: (cases) {
              final activeCases = cases.where((c) => c.status != 'COMPLETED' && c.status != 'CLOSED').toList();
              if (activeCases.isEmpty) return const SizedBox.shrink();

              return ref.watch(soldiersProvider).when(
                data: (soldiers) {
                  return Column(
                    children: activeCases.map((medCase) {
                      final soldier = soldiers.firstWhere((s) => s.id == medCase.soldierId, orElse: () => Soldier(id: medCase.soldierId, name: 'חייל לא ידוע'));

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
                        child: Dismissible(
                          key: Key(medCase.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            final String? notes = await _showSummaryBottomSheet(context);
                            if (notes == null) return false;

                            final updatedCase = {
                              'id': medCase.id,
                              'soldier_id': medCase.soldierId,
                              'status': 'COMPLETED',
                              'description': medCase.description,
                              'created_date': medCase.createdDate,
                              'updated_date': DateTime.now().toIso8601String(),
                              'closed_date': DateTime.now().toIso8601String(),
                            };

                            if (notes.trim().isNotEmpty) {
                              updatedCase['description'] = '${updatedCase['description'] ?? ''}\n\n[סיכום טיפול]: $notes'.trim();
                            }

                            try {
                              await Supabase.instance.client
                                  .from('medical_cases')
                                  .update(updatedCase)
                                  .eq('id', medCase.id);
                            } catch (_) {
                              try {
                                await SyncEngine().queueMutation(
                                  entityType: 'medical_cases',
                                  action: 'UPDATE',
                                  entityId: medCase.id,
                                  payload: updatedCase,
                                );
                              } catch (_) {}
                            }

                            return true;
                          },
                          onDismissed: (direction) {
                            if (mounted) {
                              ref.read(medicalCasesProvider.notifier).refresh();
                              ref.invalidate(dashboardMetricsProvider);
                              HopalFeedback.showSuccess(context, 'הטיפול סומן כהושלם');
                            }
                          },
                          background: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen,
                              borderRadius: AppTheme.radiusLg,
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(LucideIcons.checkCheck, color: Colors.white),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => MedicalCaseDetailScreen(medicalCase: medCase)),
                              ).then((_) => ref.read(medicalCasesProvider.notifier).refresh());
                            },
                            child: HopalCard(
                              padding: const EdgeInsets.all(AppTheme.spacing16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      HopalStatusBadge(
                                        label: '',
                                        icon: LucideIcons.user,
                                        variant: medCase.status == 'REQUIRES_ATTENTION' ? HopalStatusBadgeVariant.critical : HopalStatusBadgeVariant.info,
                                      ),
                                      const SizedBox(width: AppTheme.spacing12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(soldier.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.textPrimary)),
                                            if (medCase.description != null && medCase.description!.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(medCase.description!, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppTheme.spacing12),
                                  Divider(color: AppTheme.borderSubtle),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () async {
                                          final text = 'היי ד"ר, מצ"ב פנייה של ${soldier.name}.\nתלונות: ${medCase.description ?? 'אין תיאור'}.\nאשמח להנחיות.';
                                          if (medCase.imagePath != null && medCase.imagePath!.isNotEmpty) {
                                            await Share.shareXFiles([XFile(medCase.imagePath!)], text: text);
                                          } else {
                                            await Share.share(text);
                                          }
                                        },
                                        icon: const Icon(LucideIcons.stethoscope, size: 18),
                                        label: const Text('התייעצות רופא'),
                                        style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGreen),
                                      ),
                                      TextButton.icon(
                                        onPressed: () async {
                                          final phone = soldier.phoneNumber ?? '';
                                          if (phone.isEmpty) {
                                            HopalFeedback.showError(context, 'לא מוגדר מספר טלפון לחייל זה');
                                            return;
                                          }
                                          final text = Uri.encodeComponent('היי ${soldier.name}, מה המצב הבוקר?');
                                          var formattedPhone = phone;
                                          if (phone.startsWith('0')) formattedPhone = '972${phone.substring(1)}';
                                          final url = Uri.parse('https://wa.me/$formattedPhone?text=$text');
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(url);
                                          }
                                        },
                                        icon: const Icon(LucideIcons.messageCircle, size: 18),
                                        label: const Text('שליחת הודעה לחייל'),
                                        style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => const SizedBox.shrink(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItemRow({required IconData icon, required String title, required String description, required HopalStatusBadgeVariant variant, required Widget targetScreen}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetScreen),
        );
      },
      borderRadius: AppTheme.radiusLg,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Row(
          children: [
            HopalStatusBadge(label: '', icon: icon, variant: variant),
            const SizedBox(width: AppTheme.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(description, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronLeft, color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final isCompanyMedic = AuthService().isCompanyMedic;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, AppTheme.spacing32, AppTheme.spacing16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: HopalButton(
                  label: 'פנייה חדשה',
                  icon: LucideIcons.plusCircle,
                  isExpanded: true,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MedicalCaseCreateScreen(),
                      ),
                    );
                  },
                ),
              ),
              if (isCompanyMedic) ...[
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  flex: 2,
                  child: HopalButton(
                    label: 'מאגר חיילים',
                    icon: LucideIcons.users,
                    isExpanded: true,
                    variant: HopalButtonVariant.secondary,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SoldiersManagementScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TriviaScreen(),
                ),
              );
            },
            borderRadius: AppTheme.radiusMd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary,
                borderRadius: AppTheme.radiusMd,
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.brain, color: AppTheme.primaryGreen, size: 18),
                  const SizedBox(width: 10),
                  Text('תרגול יומי לחובש (טריוויה רפואית)',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Icon(LucideIcons.chevronLeft, color: AppTheme.textSecondary, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalStatus(DashboardMetrics metrics) {
    final standbyCount = metrics.activeMedics.where((m) => m['standby'] == true).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, AppTheme.spacing32, AppTheme.spacing16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('סטטוס גזרתי', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary, fontSize: 18)),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            children: [
              Expanded(
                child: _buildStatusCard('פניות פתוחות', '${metrics.activeMedicalCases}', LucideIcons.activity),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: _buildStatusCard(
                  'חובשים במוצב',
                  '$standbyCount/${metrics.activeMedics.length}',
                  LucideIcons.shieldCheck,
                  onTap: () => _showMedicsBottomSheet(context, metrics.activeMedics),
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: _buildStatusCard(
                  'כשירות ציוד',
                  '${metrics.equipmentReadinessPercent}%',
                  LucideIcons.briefcase,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EquipmentListScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, IconData icon, {VoidCallback? onTap}) {
    return HopalCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundTertiary,
              borderRadius: AppTheme.radiusMd,
            ),
            child: Icon(icon, color: AppTheme.militaryOlive, size: 20),
          ),
          const SizedBox(height: AppTheme.spacing24),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, letterSpacing: -0.5)),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(title, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _shareMedicsReportWithBattalionMedic(List<Map<String, dynamic>> medics) async {
    final onStandby = medics.where((m) => m['standby'] == true).toList();
    final user = AuthService().currentUser;
    final unitLabel = user?.unitName ?? 'הפלוגה';
    final depLabel = user?.activeDeploymentName;
    final header = (depLabel != null && depLabel.isNotEmpty)
        ? 'מצבת חובשים במוצב – $unitLabel ($depLabel):'
        : 'מצבת חובשים במוצב – $unitLabel:';

    final listText = onStandby.isEmpty
        ? '• אין חובשים מסומנים במוצב כרגע'
        : onStandby.map((m) {
            final platoon = m['platoon'] as String?;
            return (platoon != null && platoon.isNotEmpty)
                ? '• ${m['name']} ($platoon)'
                : '• ${m['name']}';
          }).join('\n');

    final report = '$header\nסה"כ במוצב: ${onStandby.length} מתוך ${medics.length}\n\nפירוט:\n$listText';
    final waUri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(report)}');
    if (await canLaunchUrl(waUri)) {
      await launchUrl(waUri, mode: LaunchMode.externalApplication);
    } else {
      await Share.share(report);
    }
  }

  void _showMedicsBottomSheet(BuildContext context, List<Map<String, dynamic>> initialMedics) async {
    final unitId = AuthService().currentUser?.unitId;
    final isCompanyMedic = AuthService().isCompanyMedic;
    final manualMedics = await StandbyMedicsService.getManualMedics(unitId);
    if (!context.mounted) return;

    final medics = initialMedics.map((m) => Map<String, dynamic>.from(m)).toList();
    for (final m in manualMedics) {
      final idx = medics.indexWhere((x) => x['id'] == m['id'] || (x['name'] == m['name'] && x['is_manual'] == true));
      if (idx != -1) {
        medics[idx] = m;
      } else {
        medics.add(m);
      }
    }
    final currentUserId = AuthService().currentUser?.id;

    Future<void> addMedic(StateSetter setModalState) async {
      final nameController = TextEditingController();
      final phoneController = TextEditingController();
      final platoonController = TextEditingController();

      final soldiers = ref.read(soldiersProvider).asData?.value ?? [];

      final result = await showDialog<Map<String, String>?>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.backgroundSecondary,
              title: Row(
                children: [
                  Icon(LucideIcons.userPlus, color: AppTheme.primaryGreen, size: 22),
                  const SizedBox(width: 8),
                  Text('הוספת חובש לרשימה', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'באפשרותך לצרף חובש למצבת החובשים ידנית, גם אם עדיין לא נכנס לאפליקציה במכשיר שלו.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    if (soldiers.isNotEmpty) ...[
                      DropdownButtonFormField<Soldier>(
                        dropdownColor: AppTheme.backgroundSecondary,
                        style: TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'או בחר חייל ממאגר הפלוגה',
                          prefixIcon: const Icon(LucideIcons.users),
                          border: OutlineInputBorder(borderRadius: AppTheme.radiusMd),
                        ),
                        items: soldiers.map((s) {
                          final sub = [s.personalNumber, s.platoon].whereType<String>().where((x) => x.isNotEmpty).join(' • ');
                          return DropdownMenuItem<Soldier>(
                            value: s,
                            child: Text(sub.isEmpty ? s.name : '${s.name} ($sub)'),
                          );
                        }).toList(),
                        onChanged: (s) {
                          if (s != null) {
                            setDialogState(() {
                              nameController.text = s.name;
                              if (s.phoneNumber != null) phoneController.text = s.phoneNumber!;
                              if (s.platoon != null) platoonController.text = s.platoon!;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                    ],
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'שם מלא של החובש *',
                        prefixIcon: const Icon(LucideIcons.user),
                        border: OutlineInputBorder(borderRadius: AppTheme.radiusMd),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'מספר טלפון (לחיוג ו-WhatsApp)',
                        prefixIcon: const Icon(LucideIcons.phone),
                        border: OutlineInputBorder(borderRadius: AppTheme.radiusMd),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    TextField(
                      controller: platoonController,
                      style: TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'מחלקה (לדוגמה: מחלקה 1 / חפ"ק)',
                        prefixIcon: const Icon(LucideIcons.shield),
                        border: OutlineInputBorder(borderRadius: AppTheme.radiusMd),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: Text('ביטול', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final n = nameController.text.trim();
                    if (n.isEmpty) {
                      HopalFeedback.showError(ctx, 'יש להזין שם חובש');
                      return;
                    }
                    Navigator.pop(ctx, {
                      'name': n,
                      'phone': phoneController.text.trim(),
                      'platoon': platoonController.text.trim(),
                    });
                  },
                  child: const Text('הוסף לרשימה', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        ),
      );

      if (result == null) return;
      final name = result['name']!;
      final phone = result['phone']?.isEmpty == true ? null : result['phone'];
      final platoon = result['platoon']?.isEmpty == true ? null : result['platoon'];

      final unitId = AuthService().currentUser?.unitId;
      final newId = const Uuid().v4();

      final medicData = <String, dynamic>{
        'id': newId,
        'name': name,
        'role': 'COMBAT_MEDIC',
        'phone_number': phone,
        'platoon': platoon,
        'is_manual': true,
        'standby': true,
      };

      await StandbyMedicsService.saveManualMedic(unitId, medicData);

      setModalState(() {
        final existingIdx = medics.indexWhere((m) => m['id'] == newId);
        if (existingIdx != -1) {
          medics[existingIdx] = medicData;
        } else {
          medics.add(medicData);
        }
      });

      ref.invalidate(dashboardMetricsProvider);

      if (context.mounted) {
        HopalFeedback.showSuccess(context, 'החובש $name נוסף בהצלחה');
      }
    }

    Future<void> removeMedic(StateSetter setModalState, Map<String, dynamic> medic) async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.backgroundSecondary,
          title: Text('הסרת חובש', style: TextStyle(color: AppTheme.textPrimary)),
          content: Text('להסיר את ${medic['name']} מרשימת החובשים?', style: TextStyle(color: AppTheme.textSecondary)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('ביטול', style: TextStyle(color: AppTheme.textSecondary))),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('הסר', style: TextStyle(color: AppTheme.criticalRed, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (ok != true) return;
      final unitId = AuthService().currentUser?.unitId;
      if (medic['is_manual'] == true) {
        await StandbyMedicsService.removeManualMedic(unitId, medic['id']);
      } else {
        try {
          await Supabase.instance.client
              .from('users')
              .update({'unit_id': null, 'is_on_standby': false})
              .eq('id', medic['id']);
        } catch (_) {}
      }
      setModalState(() => medics.removeWhere((m) => m['id'] == medic['id']));
      ref.invalidate(dashboardMetricsProvider);
      if (context.mounted) {
        HopalFeedback.showSuccess(context, 'החובש ${medic['name']} הוסר בהצלחה');
      }
    }

    HopalBottomSheet.show(
      context: context,
      title: 'חובשים במוצב / בכוננות',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (isCompanyMedic) ...[
                HopalButton(
                  label: 'דיווח מצבת חובשים לחוג"ד (WhatsApp)',
                  icon: LucideIcons.messageCircle,
                  onPressed: () => _shareMedicsReportWithBattalionMedic(medics),
                ),
                const SizedBox(height: AppTheme.spacing8),
                HopalButton(
                  key: const Key('add_medic_tile'),
                  label: 'הוסף חובש לרשימה (ידני / ממאגר)',
                  icon: LucideIcons.userPlus,
                  variant: HopalButtonVariant.secondary,
                  onPressed: () => addMedic(setModalState),
                ),
                const SizedBox(height: AppTheme.spacing16),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
                  child: Text(
                    'סמן את עצמך כזמין כשאתה נמצא במוצב / בגזרה. ניתן לחייג או לשלוח הודעה לחובשים בפלוגה.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ),
              ],
              if (medics.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundSecondary,
                    borderRadius: AppTheme.radiusMd,
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      Icon(LucideIcons.users, size: 36, color: AppTheme.textMuted),
                      const SizedBox(height: AppTheme.spacing8),
                      Text('אין עדיין חובשים ברשימה', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ...medics.map((medic) {
                final isMe = medic['id'] == currentUserId;
                final isManual = medic['is_manual'] == true;
                final phone = medic['phone_number'] as String?;
                final platoon = medic['platoon'] as String?;
                final canToggleThisMedic = isCompanyMedic || isMe;

                return Container(
                  margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundSecondary,
                    borderRadius: AppTheme.radiusMd,
                    border: Border.all(
                      color: medic['standby'] == true
                          ? AppTheme.primaryGreen.withValues(alpha: 0.3)
                          : AppTheme.borderSubtle,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: medic['standby'] == true
                          ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                          : AppTheme.backgroundTertiary,
                      child: Icon(
                        LucideIcons.stethoscope,
                        color: medic['standby'] == true ? AppTheme.primaryGreen : AppTheme.textMuted,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            isMe ? '${medic['name']} (אני)' : medic['name'] ?? '',
                            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isManual && isCompanyMedic) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundTertiary,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: Text('ידני', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                          ),
                        ],
                      ],
                    ),
                    subtitle: platoon != null || phone != null
                        ? Text(
                            [if (platoon != null) platoon, if (phone != null) phone].join(' • '),
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (phone != null && phone.isNotEmpty) ...[
                          IconButton(
                            icon: Icon(LucideIcons.phone, size: 18, color: AppTheme.primaryGreen),
                            tooltip: 'חיוג',
                            onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                          ),
                          IconButton(
                            icon: Icon(LucideIcons.messageCircle, size: 18, color: AppTheme.successGreen),
                            tooltip: 'WhatsApp',
                            onPressed: () {
                              final clean = phone.replaceAll(RegExp(r'\D'), '');
                              final formatted = clean.startsWith('0') ? '972${clean.substring(1)}' : clean;
                              launchUrl(Uri.parse('https://wa.me/$formatted'), mode: LaunchMode.externalApplication);
                            },
                          ),
                        ],
                        CupertinoSwitch(
                          value: medic['standby'] == true,
                          activeTrackColor: AppTheme.successGreen,
                          inactiveTrackColor: AppTheme.backgroundTertiary,
                          onChanged: canToggleThisMedic
                              ? (bool value) async {
                                  setModalState(() => medic['standby'] = value);
                                  final unitId = AuthService().currentUser?.unitId;
                                  if (medic['is_manual'] == true) {
                                    await StandbyMedicsService.updateStandby(unitId, medic['id'], value);
                                  } else {
                                    try {
                                      await Supabase.instance.client
                                          .from('users')
                                          .update({'is_on_standby': value})
                                          .eq('id', medic['id']);
                                    } catch (e) {
                                      setModalState(() => medic['standby'] = !value);
                                      if (context.mounted) HopalFeedback.showError(context, AppErrorHelper.toHebrew(e, fallback: 'שגיאה בעדכון כוננות החובש.'));
                                      return;
                                    }
                                  }
                                  ref.invalidate(dashboardMetricsProvider);
                                }
                              : null,
                        ),
                        if (isCompanyMedic && !isMe)
                          IconButton(
                            tooltip: 'הסר חובש',
                            icon: Icon(LucideIcons.trash2, color: AppTheme.criticalRed, size: 18),
                            onPressed: () => removeMedic(setModalState, medic),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              if (isCompanyMedic) ...[
                const SizedBox(height: AppTheme.spacing16),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundTertiary.withValues(alpha: 0.5),
                    borderRadius: AppTheme.radiusMd,
                  ),
                  child: ListTile(
                    leading: Icon(LucideIcons.share2, color: AppTheme.textSecondary, size: 20),
                    title: Text('שלח קוד פלוגה לחובשים להצטרפות באפליקציה', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    subtitle: Text('חובשים שיפתחו את האפליקציה יוכלו להזין את הקוד ולהתחבר ישירות', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    onTap: () {
                      final code = AuthService().currentUser?.unitJoinCode ?? '';
                      if (code.isNotEmpty) {
                        Share.share('היי, קוד הפלוגה שלנו באפליקציית חופ"ל הוא:\n$code\nהצטרף לפלוגה כדי לסנכרן ציוד וכוננות בזמן אמת!');
                      }
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<String?> _showSummaryBottomSheet(BuildContext context) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final controller = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacing24,
            left: AppTheme.spacing24,
            right: AppTheme.spacing24,
            top: AppTheme.spacing24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('סיכום טיפול', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: AppTheme.spacing8),
              Text('סגירת התיק: הזן סיכום רפואי (אופציונלי). לחץ על "סגור תיק" גם בלי להקליד כדי לדלג.', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              const SizedBox(height: AppTheme.spacing24),
              TextField(
                controller: controller,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'הקלד סיכום רפואי...',
                  hintStyle: TextStyle(color: AppTheme.textMuted),
                  prefixIcon: Icon(LucideIcons.fileText, color: AppTheme.militaryOlive),
                  filled: true,
                  fillColor: AppTheme.backgroundTertiary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd.topLeft.x),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),
              Row(
                children: [
                  Expanded(
                    child: HopalButton(
                      label: 'ביטול סגירה',
                      variant: HopalButtonVariant.secondary,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing16),
                  Expanded(
                    child: HopalButton(
                      label: 'סגור תיק',
                      icon: LucideIcons.checkCircle2,
                      onPressed: () => Navigator.pop(context, controller.text),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleScheduleEventDirectly(Map<String, dynamic> event) async {
    if (event['id'] == null) return;
    HapticFeedback.selectionClick();
    final nextDone = !(event['is_done'] == true);
    final baseIcon = (event['icon'] ?? 'clock').toString();
    try {
      await Supabase.instance.client
          .from('daily_schedule')
          .update({
            'is_done': nextDone,
            'icon': encodeScheduleIconForToday(baseIcon, isDone: nextDone),
          })
          .eq('id', event['id']);
      ref.invalidate(dashboardMetricsProvider);
    } catch (e) {
      if (mounted) {
        HopalFeedback.showError(
          context,
          AppErrorHelper.toHebrew(e, fallback: 'שגיאה בעדכון המשימה בלו"ז.'),
        );
      }
    }
  }

  Future<void> _seedRecommendedSchedule() async {
    final user = AuthService().currentUser;
    if (user?.unitId == null) return;

    try {
      await Supabase.instance.client.from('daily_schedule').insert([
        {
          'unit_id': user!.unitId,
          'time': '08:00',
          'title': 'מסדר חולים בוקר',
          'icon': 'stethoscope',
          'is_done': false,
          'actor': 'חופ"ל / חובש תורן',
        },
        {
          'unit_id': user.unitId,
          'time': '12:30',
          'title': 'בדיקת כוננות וחוסרים בארגז חופ"ל',
          'icon': 'package',
          'is_done': false,
          'actor': 'חופ"ל',
        },
        {
          'unit_id': user.unitId,
          'time': '20:00',
          'title': 'מעקב פניות פתוחות ותדריך כוננות לילה',
          'icon': 'clock',
          'is_done': false,
          'actor': 'חופ"ל',
        },
      ]);
      ref.invalidate(dashboardMetricsProvider);
      if (mounted) {
        HopalFeedback.showSuccess(context, 'לו"ז השגרה היומי נטען בהצלחה');
      }
    } catch (e) {
      if (mounted) {
        HopalFeedback.showError(
          context,
          AppErrorHelper.toHebrew(e, fallback: 'שגיאה בטעינת לו"ז השגרה.'),
        );
      }
    }
  }

  Widget _buildDailyTimeline(DashboardMetrics metrics) {
    final isCompanyMedic = AuthService().isCompanyMedic;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, AppTheme.spacing32, AppTheme.spacing16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('לו"ז יומי', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary, fontSize: 18)),
                    const SizedBox(height: 2),
                    Text(
                      'מתאפס אוטומטית בכל בוקר • לחץ על משימה לסימון V',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isCompanyMedic)
                ElevatedButton.icon(
                  onPressed: () => _showEditTimelineBottomSheet(context, metrics),
                  icon: const Icon(LucideIcons.pencil, size: 16, color: Colors.white),
                  label: const Text('עריכת לו"ז', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          HopalCard(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: metrics.timelineEvents.isEmpty
                ? Column(
                    children: [
                      Icon(LucideIcons.calendarCheck, size: 32, color: AppTheme.textMuted),
                      const SizedBox(height: AppTheme.spacing8),
                      Text(
                        'טרם הוגדרו משימות קבועות בלו"ז היומי',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      if (isCompanyMedic) ...[
                        const SizedBox(height: AppTheme.spacing16),
                        HopalButton(
                          label: 'טען משימות שגרה יומיות',
                          icon: LucideIcons.sparkles,
                          variant: HopalButtonVariant.secondary,
                          onPressed: _seedRecommendedSchedule,
                        ),
                      ],
                    ],
                  )
                : HopalTimeline(
                    events: metrics.timelineEvents.asMap().entries.map((entry) {
                      final index = entry.key;
                      final event = entry.value;
                      final isWarning = event['iconColor'] == 'warning';

                      IconData iconData = LucideIcons.circle;
                      if (event['icon'] == 'clock') iconData = LucideIcons.clock;
                      if (event['icon'] == 'stethoscope') iconData = LucideIcons.stethoscope;
                      if (event['icon'] == 'package') iconData = LucideIcons.packageSearch;

                      return HopalTimelineEvent(
                        icon: iconData,
                        iconColor: isWarning ? AppTheme.warningAmber : AppTheme.militaryOlive,
                        time: event['time'] ?? '',
                        title: event['title'] ?? '',
                        actor: event['actor'] ?? '',
                        isLast: index == metrics.timelineEvents.length - 1,
                        isDone: event['is_done'] == true,
                        onTap: () => _toggleScheduleEventDirectly(event),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  void _showEditTimelineBottomSheet(BuildContext context, DashboardMetrics metrics) {
    final events = metrics.timelineEvents.map((e) => Map<String, dynamic>.from(e)).toList();
    final schedule = Supabase.instance.client.from('daily_schedule');

    void sortEvents() => events.sort((a, b) => (a['time'] ?? '').toString().compareTo((b['time'] ?? '').toString()));

    HopalBottomSheet.show(
      context: context,
      title: 'עריכת לו"ז יומי קבוע',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'המשימות ברשימה נשמרות באופן קבוע ומתאפסות אוטומטית בתחילת כל יום חדש.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: AppTheme.spacing12),
              if (events.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  child: Text('הלו"ז ריק. השתמש בכפתור למטה כדי להוסיף משימות קבועות.', style: TextStyle(color: AppTheme.textSecondary)),
                ),
              ...events.map((event) {
                return CheckboxListTile(
                  title: Text(event['title'] ?? '', style: TextStyle(color: AppTheme.textPrimary)),
                  subtitle: Text(event['time'] ?? '', style: TextStyle(color: AppTheme.textSecondary)),
                  value: event['is_done'] == true,
                  activeColor: AppTheme.primaryGreen,
                  onChanged: (val) async {
                    final nextDone = val == true;
                    final baseIcon = (event['icon'] ?? 'clock').toString();
                    setModalState(() => event['is_done'] = nextDone);
                    try {
                      await schedule
                          .update({
                            'is_done': nextDone,
                            'icon': encodeScheduleIconForToday(baseIcon, isDone: nextDone),
                          })
                          .eq('id', event['id']);
                      ref.invalidate(dashboardMetricsProvider);
                    } catch (e) {
                      setModalState(() => event['is_done'] = !nextDone);
                      if (context.mounted) HopalFeedback.showError(context, AppErrorHelper.toHebrew(e, fallback: 'שגיאה בעדכון המשימה בלו"ז.'));
                    }
                  },
                  secondary: IconButton(
                    icon: Icon(LucideIcons.trash2, color: AppTheme.criticalRed),
                    onPressed: () async {
                      try {
                        await schedule.delete().eq('id', event['id']);
                        setModalState(() => events.remove(event));
                        ref.invalidate(dashboardMetricsProvider);
                      } catch (e) {
                        if (context.mounted) HopalFeedback.showError(context, AppErrorHelper.toHebrew(e, fallback: 'שגיאה במחיקת המשימה מהלו"ז.'));
                      }
                    },
                  ),
                );
              }),
              const SizedBox(height: AppTheme.spacing16),
              HopalButton(
                key: const Key('schedule_add_task'),
                label: 'הוסף משימה קבועה',
                icon: LucideIcons.plus,
                variant: HopalButtonVariant.secondary,
                onPressed: () async {
                  final now = DateTime.now();
                  final timeController = TextEditingController(
                      text: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}');
                  final titleController = TextEditingController();

                  final result = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppTheme.backgroundSecondary,
                      title: Text('הוספת משימה ללו"ז', style: TextStyle(color: AppTheme.textPrimary)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: timeController,
                            style: TextStyle(color: AppTheme.textPrimary),
                            decoration: InputDecoration(labelText: 'שעה (HH:MM)', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                          ),
                          TextField(
                            controller: titleController,
                            autofocus: true,
                            style: TextStyle(color: AppTheme.textPrimary),
                            decoration: InputDecoration(labelText: 'שם המשימה', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('ביטול', style: TextStyle(color: AppTheme.textSecondary))),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('הוסף', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );

                  final title = titleController.text.trim();
                  if (result != true || title.isEmpty) return;

                  try {
                    final saved = await schedule
                        .insert({
                          'unit_id': AuthService().currentUser!.unitId,
                          'time': timeController.text.trim().isEmpty ? '00:00' : timeController.text.trim(),
                          'title': title,
                          'icon': 'clock',
                          'is_done': false,
                          'actor': AuthService().currentUser?.name ?? 'חופ"ל',
                        })
                        .select()
                        .single();
                    setModalState(() {
                      events.add({
                        ...saved,
                        'icon': (saved['icon'] ?? 'clock').toString().split('@').first,
                        'is_done': saved['is_done'] == true,
                        'time': (saved['time'] ?? '').toString(),
                      });
                      sortEvents();
                    });
                    ref.invalidate(dashboardMetricsProvider);
                  } catch (e) {
                    if (context.mounted) HopalFeedback.showError(context, AppErrorHelper.toHebrew(e, fallback: 'המשימה לא נשמרה. בדוק חיבור ונסה שוב.'));
                  }
                },
              ),
              const SizedBox(height: AppTheme.spacing16),
              HopalButton(
                label: 'סיום עריכה',
                icon: LucideIcons.check,
                onPressed: () {
                  Navigator.pop(context);
                  ref.invalidate(dashboardMetricsProvider);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

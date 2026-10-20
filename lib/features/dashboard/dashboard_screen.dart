import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/features/dashboard/providers.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'dart:io';
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
import 'package:chopel_app/features/learning/learning_center_screen.dart';
import 'package:chopel_app/features/medical_cases/medical_cases_list_screen.dart';
import 'package:chopel_app/features/medical_cases/medical_case_create_screen.dart';
import 'package:chopel_app/features/equipment/equipment_list_screen.dart';
import 'package:chopel_app/features/equipment/equipment_scanner_screen.dart';
import 'package:chopel_app/screens/profile_screen.dart';
import 'package:chopel_app/features/profile/soldiers_management_screen.dart';
import 'package:chopel_app/features/learning/trivia_screen.dart';
import 'package:chopel_app/features/onboarding/walkthrough_dialog.dart';
import 'package:chopel_app/core/database/database_service.dart';
import 'package:chopel_app/core/services/standby_medics_service.dart';
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
    final unitName = user?.unitName ?? 'פלוגה ג\'';
    final deploymentName = user?.activeDeploymentName ?? '';
    final subtitle = deploymentName.isNotEmpty ? 'חופ"ל $unitName - $deploymentName' : 'חופ"ל $unitName';

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, AppTheme.spacing32, AppTheme.spacing16, AppTheme.spacing24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('שלום $name', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(subtitle, style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          Row(
            children: [
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
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.4)
                  ),
                ],
              ),
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
          
          // Display actual active medical cases inbox
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
                            if (notes == null) return false; // user cancelled

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

                            await SyncEngine().queueMutation(
                              entityType: 'medical_cases',
                              action: 'UPDATE',
                              entityId: medCase.id,
                              payload: updatedCase,
                            );

                            return true;
                          },
                          onDismissed: (direction) {
                            if (mounted) {
                              ref.read(medicalCasesProvider.notifier).refresh();
                              ref.invalidate(dashboardMetricsProvider);
                              HopalFeedback.showSuccess(context, 'טיפול הסתיים');
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
                                        variant: medCase.status == 'REQUIRES_ATTENTION' ? HopalStatusBadgeVariant.critical : HopalStatusBadgeVariant.info
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
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                flex: 2,
                child: HopalButton(
                  label: 'מצבת פלוגה',
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
    final soldiersCount = ref.watch(soldiersProvider).maybeWhen(data: (s) => s.length, orElse: () => 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, AppTheme.spacing32, AppTheme.spacing16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('סטטוס גזרתי', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary, fontSize: 18)),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            children: [
              Expanded(child: _buildStatusCard('פניות פתוחות', '${metrics.activeMedicalCases}', LucideIcons.activity)),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: _buildStatusCard(
                  'בכוננות', 
                  '${metrics.activeMedics.where((m) => m['standby']).length}/${metrics.activeMedics.length}', 
                  LucideIcons.shieldCheck,
                  onTap: () => _showMedicsBottomSheet(context, metrics.activeMedics),
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: _buildStatusCard(
                  'מצבת פלוגה', 
                  '$soldiersCount', 
                  LucideIcons.users,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SoldiersManagementScreen()),
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
      padding: const EdgeInsets.all(AppTheme.spacing24),
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
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, letterSpacing: -0.5)),
          const SizedBox(height: AppTheme.spacing4),
          Text(title, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showMedicsBottomSheet(BuildContext context, List<Map<String, dynamic>> initialMedics) async {
    final unitId = AuthService().currentUser?.unitId;
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
                  Text('הוספת חובש לכוננות', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'באפשרותך לצרף חובש לרשימת הכוננות באופן ידני, גם אם עדיין לא הצטרף לאפליקציה במכשיר שלו.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    if (soldiers.isNotEmpty) ...[
                      DropdownButtonFormField<Soldier>(
                        dropdownColor: AppTheme.backgroundSecondary,
                        style: TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'או בחר חייל ממצבת הפלוגה',
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
                TextButton(
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
                  child: Text('הוסף לרשימה', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
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

      // 1. Persist locally and to Supabase
      await StandbyMedicsService.saveManualMedic(unitId, medicData);

      // 2. Add to active modal state
      setModalState(() {
        final existingIdx = medics.indexWhere((m) => m['id'] == newId);
        if (existingIdx != -1) {
          medics[existingIdx] = medicData;
        } else {
          medics.add(medicData);
        }
      });

      // 3. Invalidate dashboard metrics provider so home screen cards update immediately
      ref.invalidate(dashboardMetricsProvider);

      if (context.mounted) {
        HopalFeedback.showSuccess(context, 'החובש $name נוסף בהצלחה לכוננות');
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
      title: 'חובשים בכוננות',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Prominent add button
              HopalButton(
                key: const Key('add_medic_tile'),
                label: 'הוסף חובש לכוננות (הזנה ידנית / ממצבת)',
                icon: LucideIcons.userPlus,
                onPressed: () => addMedic(setModalState),
              ),
              const SizedBox(height: AppTheme.spacing16),
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
                      Text('אין עדיין חובשים ברשימת הכוננות', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('לחץ על הכפתור למעלה כדי להוסיף חובשים מהפלוגה', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ...medics.map((medic) {
                final isMe = medic['id'] == currentUserId;
                final isManual = medic['is_manual'] == true;
                final phone = medic['phone_number'] as String?;
                final platoon = medic['platoon'] as String?;

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
                        if (isManual) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundTertiary,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: Text('הזנה ידנית', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
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
                          onChanged: (bool value) async {
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
                                if (context.mounted) HopalFeedback.showError(context, 'שגיאה בעדכון כוננות: $e');
                                return;
                              }
                            }
                            ref.invalidate(dashboardMetricsProvider);
                          },
                        ),
                        if (!isMe)
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
              const SizedBox(height: AppTheme.spacing16),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundTertiary.withValues(alpha: 0.5),
                  borderRadius: AppTheme.radiusMd,
                ),
                child: ListTile(
                  leading: Icon(LucideIcons.share2, color: AppTheme.textSecondary, size: 20),
                  title: Text('שלח קוד פלוגה לחובשים להצטרפות באפליקציה', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  subtitle: Text('חובשים שיורידו את האפליקציה יוכלו להזין את הקוד ולהתחבר ישירות', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  onTap: () {
                    final code = AuthService().currentUser?.unitJoinCode ?? '';
                    if (code.isNotEmpty) {
                      Share.share('היי, קוד הפלוגה שלנו באפליקציית חופ"ל הוא:\n$code\nהצטרף לפלוגה כדי לסנכרן ציוד וכוננות בזמן אמת!');
                    }
                  },
                ),
              ),
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

  Widget _buildDailyTimeline(DashboardMetrics metrics) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, AppTheme.spacing32, AppTheme.spacing16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('לו"ז יומי', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary, fontSize: 18)),
              if (AuthService().currentUser != null)
                ElevatedButton.icon(
                  onPressed: () => _showEditTimelineBottomSheet(context, metrics),
                  icon: Icon(LucideIcons.pencil, size: 18, color: Colors.white),
                  label: Text('עריכת לו"ז', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 6,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    shadowColor: AppTheme.primaryGreen.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          HopalCard(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: HopalTimeline(
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
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditTimelineBottomSheet(BuildContext context, DashboardMetrics metrics) {
    // Kept outside the builder so edits survive rebuilds.
    final events = metrics.timelineEvents.map((e) => Map<String, dynamic>.from(e)).toList();
    final schedule = Supabase.instance.client.from('daily_schedule');

    void sortEvents() => events.sort((a, b) => (a['time'] ?? '').toString().compareTo((b['time'] ?? '').toString()));

    HopalBottomSheet.show(
      context: context,
      title: 'עריכת לו"ז יומי',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (events.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  child: Text('הלו"ז ריק. השתמש בכפתור למטה כדי להוסיף משימות.', style: TextStyle(color: AppTheme.textSecondary)),
                ),
              ...events.map((event) {
                return CheckboxListTile(
                  title: Text(event['title'] ?? '', style: TextStyle(color: AppTheme.textPrimary)),
                  subtitle: Text(event['time'] ?? '', style: TextStyle(color: AppTheme.textSecondary)),
                  value: event['is_done'] == true,
                  activeColor: AppTheme.primaryGreen,
                  onChanged: (val) async {
                    setModalState(() => event['is_done'] = val == true);
                    try {
                      await schedule.update({'is_done': val == true}).eq('id', event['id']);
                      ref.invalidate(dashboardMetricsProvider);
                    } catch (e) {
                      setModalState(() => event['is_done'] = val != true);
                      if (context.mounted) HopalFeedback.showError(context, 'שגיאה בעדכון: $e');
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
                        if (context.mounted) HopalFeedback.showError(context, 'שגיאה במחיקה: $e');
                      }
                    },
                  ),
                );
              }),
              const SizedBox(height: AppTheme.spacing16),
              HopalButton(
                key: const Key('schedule_add_task'),
                label: 'הוסף משימה',
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
                      title: Text('הוספת משימה', style: TextStyle(color: AppTheme.textPrimary)),
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
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text('הוסף', style: TextStyle(color: AppTheme.primaryGreen)),
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
                      events.add({...saved, 'is_done': saved['is_done'] == true, 'time': (saved['time'] ?? '').toString()});
                      sortEvents();
                    });
                    ref.invalidate(dashboardMetricsProvider);
                  } catch (e) {
                    if (context.mounted) HopalFeedback.showError(context, 'המשימה לא נשמרה: $e');
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

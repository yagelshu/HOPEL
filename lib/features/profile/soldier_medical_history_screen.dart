import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_status_badge.dart';
import 'package:chopel_app/theme/components/hopal_empty_state.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:chopel_app/core/utils/platform_image.dart';
import 'package:chopel_app/core/utils/date_formatter.dart';
import 'package:chopel_app/core/utils/platoon_helper.dart';
import 'package:chopel_app/models/soldier.dart';
import 'package:chopel_app/models/medical_case.dart';
import 'package:chopel_app/features/medical_cases/providers.dart';
import 'package:chopel_app/features/medical_cases/medical_case_create_screen.dart';
import 'package:chopel_app/features/medical_cases/medical_case_detail_screen.dart';

class SoldierMedicalHistoryScreen extends ConsumerStatefulWidget {
  final Soldier soldier;

  const SoldierMedicalHistoryScreen({super.key, required this.soldier});

  @override
  ConsumerState<SoldierMedicalHistoryScreen> createState() => _SoldierMedicalHistoryScreenState();
}

class _SoldierMedicalHistoryScreenState extends ConsumerState<SoldierMedicalHistoryScreen> {
  String _selectedFilter = 'הכל'; // 'הכל', 'פעיל', 'הושלם'

  void _openNewCase(Soldier soldier) {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicalCaseCreateScreen(initialSoldierId: soldier.id),
      ),
    );
  }

  void _openCaseDetail(MedicalCase medicalCase) {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicalCaseDetailScreen(medicalCase: medicalCase),
      ),
    );
  }

  void _showFullScreenPhoto(String imageUri, {String? tag}) {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: AppTheme.radiusMd,
                child: Image(
                  image: resolveLocalOrWebImage(imageUri),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(24),
                    color: AppTheme.backgroundSecondary,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.imageOff, color: AppTheme.criticalRed, size: 40),
                        const SizedBox(height: 8),
                        Text('שגיאה בהצגת התמונה', style: TextStyle(color: AppTheme.textPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (tag != null && tag.isNotEmpty)
              Positioned(
                bottom: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.8)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.tag, color: AppTheme.primaryGreen, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        tag,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep soldier data fresh from provider if available
    final soldiersAsync = ref.watch(soldiersProvider);
    final freshSoldier = soldiersAsync.value?.where((s) => s.id == widget.soldier.id).firstOrNull ?? widget.soldier;

    // Fetch cases for this soldier
    final casesAsync = ref.watch(medicalCasesProvider);
    final allCases = casesAsync.value ?? <MedicalCase>[];
    final soldierCases = allCases.where((c) => c.soldierId == freshSoldier.id).toList();

    // Metrics
    final totalCases = soldierCases.length;
    final activeCases = soldierCases.where((c) => c.status != 'COMPLETED' && c.status != 'טופל').length;
    final completedCases = soldierCases.where((c) => c.status == 'COMPLETED' || c.status == 'טופל').length;
    final totalPhotos = soldierCases.fold<int>(0, (sum, c) => sum + c.photos.length);

    // Filtered cases
    final filteredCases = soldierCases.where((c) {
      if (_selectedFilter == 'פעיל') {
        return c.status != 'COMPLETED' && c.status != 'טופל';
      }
      if (_selectedFilter == 'הושלם') {
        return c.status == 'COMPLETED' || c.status == 'טופל';
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('תיק רפואי אישי', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowRight, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.filePlus2, color: AppTheme.primaryGreen),
            tooltip: 'פנייה חדשה',
            onPressed: () => _openNewCase(freshSoldier),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Soldier Profile Header Card
                  _buildSoldierHeader(freshSoldier),
                  const SizedBox(height: AppTheme.spacing16),

                  // Allergy / Sensitivity Warning Banner
                  if (freshSoldier.hasAllergies) ...[
                    _buildAllergiesBanner(freshSoldier),
                    const SizedBox(height: AppTheme.spacing16),
                  ],

                  // KPI Summary Cards
                  _buildKpiMetrics(
                    total: totalCases,
                    active: activeCases,
                    completed: completedCases,
                    photos: totalPhotos,
                  ),
                  const SizedBox(height: AppTheme.spacing16),

                  // Big Action Button
                  HopalButton(
                    label: 'פתח פנייה רפואית חדשה לחייל',
                    icon: LucideIcons.filePlus2,
                    isExpanded: true,
                    onPressed: () => _openNewCase(freshSoldier),
                  ),
                  const SizedBox(height: AppTheme.spacing24),

                  // Section Title & Filters
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'היסטוריית פניות וטיפולים ($totalCases)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5, color: AppTheme.textPrimary),
                      ),
                      Wrap(
                        spacing: 6,
                        children: ['הכל', 'פעיל', 'הושלם'].map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return ChoiceChip(
                            label: Text(
                              filter,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? AppTheme.onPrimaryGreen : AppTheme.textSecondary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            checkmarkColor: AppTheme.onPrimaryGreen,
                            backgroundColor: AppTheme.backgroundSecondary,
                            selectedColor: AppTheme.primaryGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            onSelected: (val) {
                              if (val) {
                                try {
                                  HapticFeedback.selectionClick();
                                } catch (_) {}
                                setState(() => _selectedFilter = filter);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Cases List or Empty State
          if (filteredCases.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing32),
                child: HopalEmptyState(
                  icon: LucideIcons.folderHeart,
                  title: totalCases == 0 ? 'אין תיקים רפואיים קודמים' : 'אין פניות תואמות לסינון',
                  subtitle: totalCases == 0
                      ? 'זהו תיק אישי חדש. לחץ על "פתח פנייה רפואית חדשה לחייל" כדי לתעד ביקור, תלונה, תמונות וטיפול.'
                      : 'נסה לבחור בסינון "הכל" כדי לצפות בכל היסטוריית הטיפולים של החייל.',
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filteredCases[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
                      child: _buildCaseCard(item),
                    );
                  },
                  childCount: filteredCases.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildSoldierHeader(Soldier soldier) {
    final hasPhone = soldier.phoneNumber != null && soldier.phoneNumber!.trim().isNotEmpty;
    final platoonText = soldier.platoon != null && soldier.platoon!.trim().isNotEmpty
        ? PlatoonHelper.formatDisplay(soldier.platoon)
        : 'ללא מחלקה';

    return HopalCard(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      borderColor: soldier.hasAllergies ? AppTheme.criticalRed.withValues(alpha: 0.5) : AppTheme.borderSubtle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: soldier.hasAllergies
                    ? AppTheme.criticalRed.withValues(alpha: 0.15)
                    : AppTheme.primaryGreen.withValues(alpha: 0.15),
                child: Icon(
                  soldier.hasAllergies ? LucideIcons.alertTriangle : LucideIcons.user,
                  color: soldier.hasAllergies ? AppTheme.criticalRed : AppTheme.primaryGreen,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      soldier.name,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (soldier.personalNumber != null && soldier.personalNumber!.isNotEmpty)
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: soldier.personalNumber!));
                              HopalFeedback.showInfo(context, 'מספר אישי הועתק ללוח');
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.idCard, size: 14, color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  'מ.א ${soldier.personalNumber}',
                                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.shield, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              platoonText,
                              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (hasPhone) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.infoBlue,
                      side: BorderSide(color: AppTheme.infoBlue.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(LucideIcons.phone, size: 16),
                    label: Text(soldier.phoneNumber!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      final clean = soldier.phoneNumber!.replaceAll(RegExp(r'\D'), '');
                      final uri = Uri.parse('tel:$clean');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.successGreen,
                      side: BorderSide(color: AppTheme.successGreen.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(LucideIcons.messageCircle, size: 16),
                    label: const Text('WhatsApp', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      var phone = soldier.phoneNumber!.replaceAll(RegExp(r'\D'), '');
                      if (phone.startsWith('0')) phone = '972${phone.substring(1)}';
                      final uri = Uri.parse('https://wa.me/$phone');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAllergiesBanner(Soldier soldier) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.criticalRed.withValues(alpha: 0.12),
        borderRadius: AppTheme.radiusMd,
        border: Border.all(color: AppTheme.criticalRed.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.alertTriangle, color: AppTheme.criticalRed, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'דגל רפואי קריטי: אלרגיה / רגישות ידועה',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.criticalRed),
                ),
                const SizedBox(height: 4),
                Text(
                  soldier.allergies ?? '',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'חובה לוודא אי-מתן תרופות אסורות (כגון G6PD, NSAID או פניצילין בהתאם לרישום).',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetrics({
    required int total,
    required int active,
    required int completed,
    required int photos,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'סה"כ פניות',
            count: '$total',
            icon: LucideIcons.stethoscope,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: 'בטיפול',
            count: '$active',
            icon: LucideIcons.hourglass,
            color: active > 0 ? AppTheme.warningAmber : AppTheme.textMuted,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: 'הושלמו',
            count: '$completed',
            icon: LucideIcons.checkCircle2,
            color: AppTheme.successGreen,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: 'תמונות',
            count: '$photos',
            icon: LucideIcons.camera,
            color: AppTheme.infoBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: AppTheme.radiusMd,
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildCaseCard(MedicalCase item) {
    final isDone = item.status == 'COMPLETED' || item.status == 'טופל';
    final photos = item.photos;

    return HopalCard(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      onTap: () => _openCaseDetail(item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Case Header: Date & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.calendar, size: 15, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    DateFormatter.formatRelative(item.createdDate),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              HopalStatusBadge(
                label: isDone ? 'הושלם' : 'בטיפול / מעקב',
                variant: isDone ? HopalStatusBadgeVariant.neutral : HopalStatusBadgeVariant.warning,
                icon: isDone ? LucideIcons.checkCircle : LucideIcons.stethoscope,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Category & Severity
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (item.category != null && item.category!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.category!,
                    style: TextStyle(fontSize: 11.5, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                  ),
                ),
              if (item.severity != null && item.severity!.isNotEmpty && item.severity != 'שגרה')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.criticalRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.severity!,
                    style: TextStyle(fontSize: 11.5, color: AppTheme.criticalRed, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Clinical Description
          Text(
            item.description ?? 'אין תיאור רפואי',
            style: TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.4),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          // Photos Strip (if any)
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, pIdx) {
                  final photo = photos[pIdx];
                  return InkWell(
                    onTap: () => _showFullScreenPhoto(photo.path, tag: photo.complaintTag),
                    borderRadius: AppTheme.radiusSm,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: AppTheme.radiusSm,
                          child: Container(
                            width: 72,
                            height: 72,
                            color: AppTheme.backgroundTertiary,
                            child: Image(
                              image: resolveLocalOrWebImage(photo.path),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(LucideIcons.imageOff, color: AppTheme.textMuted, size: 20),
                              ),
                            ),
                          ),
                        ),
                        if (photo.complaintTag != null && photo.complaintTag!.isNotEmpty)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            left: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                photo.complaintTag!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'צפה בפרטי התיק והטיפול',
                style: TextStyle(fontSize: 12.5, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Icon(LucideIcons.chevronLeft, size: 16, color: AppTheme.primaryGreen),
            ],
          ),
        ],
      ),
    );
  }
}

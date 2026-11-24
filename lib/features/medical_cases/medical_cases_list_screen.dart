import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/features/medical_cases/providers.dart';
import 'package:chopel_app/features/medical_cases/medical_case_detail_screen.dart';
import 'package:chopel_app/models/medical_case.dart';
import 'package:chopel_app/models/soldier.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';
import 'package:chopel_app/theme/components/hopal_status_badge.dart';
import 'package:chopel_app/theme/components/hopal_empty_state.dart';
import 'package:chopel_app/theme/components/hopal_search_bar.dart';
import 'package:chopel_app/theme/components/hopal_fab.dart';
import 'package:chopel_app/features/medical_cases/medical_case_create_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:chopel_app/theme/components/hopal_shimmer.dart';
import 'package:chopel_app/core/utils/date_formatter.dart';
import 'package:chopel_app/core/services/battalion_staff_service.dart';
import 'package:chopel_app/core/services/csv_export_service.dart';
import 'package:chopel_app/core/utils/platoon_helper.dart';
import 'package:chopel_app/features/dashboard/widgets/matab_queue_card.dart';

class MedicalCasesListScreen extends ConsumerStatefulWidget {
  const MedicalCasesListScreen({super.key});

  @override
  ConsumerState<MedicalCasesListScreen> createState() => _MedicalCasesListScreenState();
}

class _MedicalCasesListScreenState extends ConsumerState<MedicalCasesListScreen> {
  String _filter = 'ALL'; // ALL, MATAB_QUEUE, COMPLETED
  String _selectedPlatoon = 'הכל';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final casesAsyncValue = ref.watch(medicalCasesProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: casesAsyncValue.when(
        data: (cases) {
          final soldiersAsync = ref.watch(soldiersProvider);
          final soldiers = soldiersAsync.value ?? [];
          final platoons = PlatoonHelper.extractPlatoons(
            soldiers,
            (s) => s.platoon,
            alwaysIncludeAttached: true,
          );
          final matabQueueCount = cases.where(BattalionStaffService.isCaseInMatabQueue).length;

          List<MedicalCase> filteredCases = cases;
          if (_filter == 'REQUIRES_ATTENTION') {
            filteredCases = cases.where((c) => c.status == 'REQUIRES_ATTENTION').toList();
          } else if (_filter == 'MATAB_QUEUE') {
            filteredCases = cases.where(BattalionStaffService.isCaseInMatabQueue).toList();
          } else if (_filter == 'COMPLETED') {
            filteredCases = cases.where((c) => c.status == 'COMPLETED').toList();
          } else {
            // ALL active (hide completed and closed by default)
            filteredCases = cases.where((c) => c.status != 'COMPLETED' && c.status != 'CLOSED').toList();
          }

          if (_selectedPlatoon != 'הכל') {
            filteredCases = filteredCases.where((c) {
              final soldier = soldiers.where((s) => s.id == c.soldierId).firstOrNull;
              return PlatoonHelper.matches(soldier?.platoon, _selectedPlatoon);
            }).toList();
          }

          if (_searchQuery.isNotEmpty) {
            filteredCases = filteredCases.where((c) {
              final soldier = soldiers.firstWhere((s) => s.id == c.soldierId, orElse: () => Soldier(id: '', name: 'לא ידוע', platoon: ''));
              final soldierName = soldier.name.toLowerCase();
              final personalNumber = (soldier.personalNumber ?? '').toLowerCase();
              final platoon = (soldier.platoon ?? '').toLowerCase();
              final desc = (c.description ?? '').toLowerCase();
              final cleanQuery = _searchQuery.replaceAll(RegExp(r'[\s-]'), '');
              final cleanPn = personalNumber.replaceAll(RegExp(r'[\s-]'), '');
              return soldierName.contains(_searchQuery) ||
                  (cleanPn.isNotEmpty && cleanPn.contains(cleanQuery)) ||
                  platoon.contains(_searchQuery) ||
                  desc.contains(_searchQuery);
            }).toList();
          }

          // Operational Sorting:
          // 1. Waiting for Physician
          // 2. Follow-up
          // 3. High Priority
          // 4. Normal
          filteredCases.sort((a, b) {
            int scoreA = _getOperationalScore(a);
            int scoreB = _getOperationalScore(b);
            if (scoreA != scoreB) return scoreB.compareTo(scoreA);
            return b.createdDate.compareTo(a.createdDate); // Newest first for same score
          });

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(medicalCasesProvider.notifier).refresh();
            },
            color: AppTheme.primaryGreen,
            backgroundColor: AppTheme.backgroundSecondary,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: const Text('פניות רפואיות פעילות', style: TextStyle(fontWeight: FontWeight.bold)),
                  floating: true,
                  pinned: true,
                  actions: [
                    IconButton(
                      icon: Icon(LucideIcons.stethoscope, color: AppTheme.primaryGreen),
                      tooltip: 'מסדר מט"ב להיום',
                      onPressed: () => MatabQueueCard.showQueueSheet(
                        context,
                        allCases: cases,
                        soldiers: soldiers,
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.download, color: AppTheme.textSecondary),
                      tooltip: 'ייצוא פניות לאקסל (CSV)',
                      onPressed: () {
                        final csv = CsvExportService.generateMedicalCasesCsv(filteredCases, soldiers);
                        CsvExportService.shareCsv(
                          csvContent: csv,
                          fileName: 'hopel_cases_${DateTime.now().toIso8601String().split('T').first}.csv',
                          title: 'דוח פניות רפואיות - חופ"ל',
                        );
                      },
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(120),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                          child: HopalSearchBar(
                            controller: _searchController,
                            placeholder: 'חיפוש חייל / פנייה...',
                            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                          ),
                        ),
                        _buildFilterChips(matabQueueCount, platoons),
                      ],
                    ),
                  ),
                ),
                if (filteredCases.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: HopalEmptyState(
                      icon: LucideIcons.checkCircle2,
                      title: 'אין פניות פעילות',
                      subtitle: 'כל הפניות טופלו בהצלחה והלו"ז נקי.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, AppTheme.spacing16, AppTheme.spacing16, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final mCase = filteredCases[index];
                          final soldier = soldiers.firstWhere((s) => s.id == mCase.soldierId, orElse: () => Soldier(id: mCase.soldierId, name: 'חייל לא ידוע', platoon: ''));
                          return _buildCaseCard(mCase, soldier)
                              .animate()
                              .fade(duration: 400.ms, delay: (index * 50).ms)
                              .slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutQuad);
                        },
                        childCount: filteredCases.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => ListView.builder(
          itemCount: 4,
          padding: const EdgeInsets.only(top: 100),
          itemBuilder: (context, index) => const HopalShimmerCard(),
        ),
        error: (err, stack) => const Center(child: Text('שגיאה בטעינת נתונים')),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120.0),
        child: HopalFAB(
          icon: LucideIcons.plus,
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
    );
  }

  int _getOperationalScore(MedicalCase c) {
    if (c.status == 'REQUIRES_ATTENTION') return 100;
    if (c.status == 'COMPLETED') return 0;
    return 50; 
  }

  Widget _buildFilterChips(int matabQueueCount, List<String> platoons) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing8),
      child: Row(
        children: [
          _buildChip('פניות פתוחות', 'ALL'),
          const SizedBox(width: AppTheme.spacing8),
          _buildChip(
            matabQueueCount > 0 ? 'מסדר מט"ב ($matabQueueCount)' : 'מסדר מט"ב',
            'MATAB_QUEUE',
          ),
          const SizedBox(width: AppTheme.spacing8),
          _buildChip('היסטוריה', 'COMPLETED'),
          if (platoons.length > 1) ...[
            const SizedBox(width: 10),
            Container(width: 1, height: 22, color: AppTheme.borderSubtle),
            const SizedBox(width: 10),
            ...platoons.where((p) => p != 'הכל').map((plt) {
              final isSelected = _selectedPlatoon == plt;
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: ChoiceChip(
                  label: Text(plt),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedPlatoon = selected ? plt : 'הכל');
                  },
                  selectedColor: AppTheme.infoBlue.withValues(alpha: 0.2),
                  backgroundColor: AppTheme.backgroundSecondary,
                  checkmarkColor: AppTheme.infoBlue,
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.infoBlue : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12.5,
                  ),
                  side: BorderSide(color: isSelected ? AppTheme.infoBlue : AppTheme.borderSubtle),
                  shape: const RoundedRectangleBorder(borderRadius: AppTheme.radiusPill),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _filter = value);
      },
      selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
      backgroundColor: AppTheme.backgroundSecondary,
      checkmarkColor: AppTheme.primaryGreen,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: isSelected ? AppTheme.primaryGreen : AppTheme.borderSubtle),
      shape: const RoundedRectangleBorder(borderRadius: AppTheme.radiusPill),
    );
  }

  Widget _buildCaseCard(MedicalCase mCase, Soldier soldier) {
    Color borderColor = AppTheme.borderSubtle;
    if (mCase.status == 'REQUIRES_ATTENTION') borderColor = AppTheme.warningAmber.withValues(alpha: 0.5);

    String statusText;
    HopalStatusBadgeVariant variant;
    IconData statusIcon;

    switch (mCase.status) {
      case 'REQUIRES_ATTENTION':
        statusText = 'נדרש המשך טיפול';
        variant = HopalStatusBadgeVariant.warning;
        statusIcon = LucideIcons.stethoscope;
        break;
      case 'COMPLETED':
        statusText = 'טיפול הושלם';
        variant = HopalStatusBadgeVariant.neutral;
        statusIcon = LucideIcons.checkCircle;
        break;
      default:
        statusText = 'לא ידוע';
        variant = HopalStatusBadgeVariant.info;
        statusIcon = LucideIcons.activity;
        break;
    }

    final formattedDate = DateFormatter.formatRelative(mCase.createdDate);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: HopalCard(
        borderColor: borderColor,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MedicalCaseDetailScreen(medicalCase: mCase),
            ),
          ).then((_) => ref.read(medicalCasesProvider.notifier).refresh());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Hero(
                  tag: 'soldier_name_${mCase.id}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(soldier.name, style: Theme.of(context).textTheme.titleMedium),
                            if (soldier.hasAllergies) ...[
                              const SizedBox(width: AppTheme.spacing8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.criticalRed.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.criticalRed.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.shieldAlert, size: 12, color: AppTheme.criticalRed),
                                    const SizedBox(width: 4),
                                    Text(
                                      soldier.allergies!,
                                      style: TextStyle(color: AppTheme.criticalRed, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (soldier.personalNumber != null)
                              Text('מ.א: ${soldier.personalNumber}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                            if (soldier.platoon != null && soldier.platoon!.isNotEmpty) ...[
                              if (soldier.personalNumber != null)
                                Text(' • ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                              Text(soldier.platoon!, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                HopalStatusBadge(label: statusText, icon: statusIcon, variant: variant),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              mCase.description ?? 'ללא תיאור מפורט',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTheme.spacing12),
            Row(
              children: [
                Icon(LucideIcons.calendar, size: 14, color: AppTheme.militaryOlive),
                const SizedBox(width: AppTheme.spacing4),
                Text('נפתח: $formattedDate', style: TextStyle(color: AppTheme.militaryOlive, fontSize: 12)),
                const Spacer(),
                if (BattalionStaffService.isCaseInMatabQueue(mCase))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.stethoscope, size: 12, color: AppTheme.primaryGreen),
                        const SizedBox(width: 4),
                        Text(
                          'במסדר מט"ב',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

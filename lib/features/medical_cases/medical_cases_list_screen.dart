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

class MedicalCasesListScreen extends ConsumerStatefulWidget {
  const MedicalCasesListScreen({super.key});

  @override
  ConsumerState<MedicalCasesListScreen> createState() => _MedicalCasesListScreenState();
}

class _MedicalCasesListScreenState extends ConsumerState<MedicalCasesListScreen> {
  String _filter = 'ALL'; // ALL, WAITING, FOLLOW_UP, CLOSED
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
          
          List<MedicalCase> filteredCases = cases;
          if (_filter == 'REQUIRES_ATTENTION') {
            filteredCases = cases.where((c) => c.status == 'REQUIRES_ATTENTION').toList();
          } else if (_filter == 'COMPLETED') {
            filteredCases = cases.where((c) => c.status == 'COMPLETED').toList();
          } else {
            // ALL active (hide completed and closed by default)
            filteredCases = cases.where((c) => c.status != 'COMPLETED' && c.status != 'CLOSED').toList();
          }

          if (_searchQuery.isNotEmpty) {
            filteredCases = filteredCases.where((c) {
              final soldier = soldiers.firstWhere((s) => s.id == c.soldierId, orElse: () => Soldier(id: '', name: 'לא ידוע', platoon: ''));
              final soldierName = soldier.name.toLowerCase();
              final desc = (c.description ?? '').toLowerCase();
              return soldierName.contains(_searchQuery) || desc.contains(_searchQuery);
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
                        _buildFilterChips(),
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
                      subtitle: 'מצוין. כל המקרים טופלו בהצלחה והלו"ז נקי ☕',
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

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing8),
      child: Row(
        children: [
          _buildChip('פניות פתוחות', 'ALL'),
          const SizedBox(width: AppTheme.spacing8),
          _buildChip('היסטוריה', 'COMPLETED'),
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
                        Text(soldier.name, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 2),
                        if (soldier.platoon != null && soldier.platoon!.isNotEmpty)
                          Text('מחלקה: ${soldier.platoon}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/features/learning/providers.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';
import 'package:chopel_app/theme/components/hopal_empty_state.dart';
import 'package:chopel_app/theme/components/hopal_search_bar.dart';
import 'package:chopel_app/models/learning_content.dart';
import 'package:chopel_app/features/learning/learning_content_viewer_screen.dart';
import 'package:chopel_app/features/learning/medication_guide_screen.dart';
import 'package:chopel_app/features/learning/meditest_screen.dart';

class LearningCenterScreen extends ConsumerStatefulWidget {
  const LearningCenterScreen({super.key});

  @override
  ConsumerState<LearningCenterScreen> createState() => _LearningCenterScreenState();
}

class _LearningCenterScreenState extends ConsumerState<LearningCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'הכל';

  Future<void> _launchUrl(String url, String title, String type) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LearningContentViewerScreen(
          title: title,
          type: type,
          url: url,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final learningAsync = ref.watch(learningContentProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: learningAsync.when(
        data: (contents) {
          // Filter by search query
          var filteredContents = contents;
          if (_searchQuery.isNotEmpty) {
            filteredContents = contents.where((c) => c.title.toLowerCase().contains(_searchQuery)).toList();
          }

          // Categories
          final allCategories = ['הכל', ...contents.map((c) => c.category).toSet()];
          
          if (_selectedCategory != 'הכל') {
            filteredContents = filteredContents.where((c) => c.category == _selectedCategory).toList();
          }

          // Group by category
          final Map<String, List<LearningContent>> groupedContents = {};
          for (var content in filteredContents) {
            groupedContents.putIfAbsent(content.category, () => []).add(content);
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: const Text('ידע מקצועי', style: TextStyle(fontWeight: FontWeight.bold)),
                floating: true,
                pinned: true,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(80),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, 0, AppTheme.spacing16, AppTheme.spacing16),
                    child: HopalSearchBar(
                      controller: _searchController,
                      placeholder: 'חיפוש פרוטוקולים, נהלים...',
                      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    ),
                  ),
                ),
              ),
              if (contents.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: HopalEmptyState(
                    icon: LucideIcons.bookOpen,
                    title: 'הספרייה ריקה',
                    subtitle: 'לא נמצאו פק"לים או מדריכים במערכת.',
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing8),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const MedicationGuideScreen()));
                            },
                            borderRadius: AppTheme.radiusMd,
                            child: Container(
                                padding: const EdgeInsets.all(AppTheme.spacing16),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen,
                                  boxShadow: [
                                    BoxShadow(color: AppTheme.primaryGreen.withValues(alpha: 0.3), blurRadius: 8, offset: Offset(0, 4)),
                                  ],
                                  borderRadius: AppTheme.radiusMd,
                                ),
                                child: Column(
                                  children: [
                                    Icon(LucideIcons.pill, color: Colors.white, size: 32),
                                    SizedBox(height: AppTheme.spacing8),
                                    Text('מדריך תרופות', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                                    Text('QXGO', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing16),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const MeditestScreen()));
                              },
                              borderRadius: AppTheme.radiusMd,
                              child: Container(
                                padding: const EdgeInsets.all(AppTheme.spacing16),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningAmber,
                                  boxShadow: [
                                    BoxShadow(color: AppTheme.warningAmber.withValues(alpha: 0.3), blurRadius: 8, offset: Offset(0, 4)),
                                  ],
                                  borderRadius: AppTheme.radiusMd,
                                ),
                                child: Column(
                                  children: [
                                    Icon(LucideIcons.brainCircuit, color: Colors.white, size: 32),
                                    SizedBox(height: AppTheme.spacing8),
                                    Text('מבחני ריענון', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                                    Text('Meditest', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing16),
                    child: Row(
                      children: allCategories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(left: AppTheme.spacing8),
                          child: ChoiceChip(
                            label: Text(cat, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary)),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedCategory = cat);
                            },
                            backgroundColor: AppTheme.backgroundSecondary,
                            selectedColor: AppTheme.primaryGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppTheme.primaryGreen : AppTheme.borderSubtle)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
              ...groupedContents.entries.map((entry) {
                final category = entry.key;
                final items = entry.value;
                return [
                  _buildSectionHeader(category, LucideIcons.folder),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildListCard(items[index]),
                        childCount: items.length,
                      ),
                    ),
                  ),
                ];
              }).expand((e) => e),
              const SliverToBoxAdapter(child: SizedBox(height: 120)), // Bottom nav padding
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (err, stack) => const Center(child: Text('שגיאה בטעינת נתונים')),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, AppTheme.spacing32, AppTheme.spacing16, AppTheme.spacing16),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: AppTheme.spacing8),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }


  Widget _buildListCard(LearningContent item) {
    final isVideo = item.type == 'VIDEO';
    final color = isVideo ? AppTheme.warningAmber : AppTheme.infoBlue;
    final icon = isVideo ? LucideIcons.playCircle : LucideIcons.fileText;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: HopalCard(
        onTap: () => _launchUrl(item.url, item.title, item.type),
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppTheme.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(isVideo ? 'סרטון הדרכה' : 'פרוטוקול טיפול', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Icon(LucideIcons.downloadCloud, color: AppTheme.primaryGreen, size: 20),
            const SizedBox(width: AppTheme.spacing16),
            Icon(LucideIcons.chevronLeft, color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

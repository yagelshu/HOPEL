import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';
import 'package:chopel_app/theme/components/hopal_search_bar.dart';

class Medication {
  final String name;
  final String activeIngredient;
  final String indications;
  final String contraindications;
  final String adultDose;
  final String sideEffects;
  final String category;

  const Medication({
    required this.name,
    required this.activeIngredient,
    required this.indications,
    required this.contraindications,
    required this.adultDose,
    required this.sideEffects,
    required this.category,
  });
}

class MedicationGuideScreen extends StatefulWidget {
  const MedicationGuideScreen({super.key});

  @override
  State<MedicationGuideScreen> createState() => _MedicationGuideScreenState();
}

class _MedicationGuideScreenState extends State<MedicationGuideScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'הכל';

  static const List<Medication> _medications = [
    Medication(
      name: 'אקמול (Acamol)',
      activeIngredient: 'Paracetamol',
      indications: 'שיכוך כאב קל עד בינוני, הורדת חום.',
      contraindications: 'רגישות ידועה לפראצטמול, פגיעה כבדית קשה.',
      adultDose: '500-1000 מ"ג (1-2 כדורים) כל 4-6 שעות. מקסימום 4 גרם ביום.',
      sideEffects: 'נדיר. במינון יתר: פגיעה כבדית קשה.',
      category: 'שיכוך כאב והורדת חום',
    ),
    Medication(
      name: 'אופטלגין (Optalgin)',
      activeIngredient: 'Dipyrone / Metamizole',
      indications: 'שיכוך כאב בינוני עד חזק (במיוחד כאב ויסרלי / עוויתי), חום גבוה שלא מגיב לתרופות אחרות.',
      contraindications: 'רגישות לאופטלגין, חסר ב-G6PD (רגישות לפול), נשים בהריון/מניקות, פגיעה במח העצם.',
      adultDose: '500-1000 מ"ג (1-2 כדורים) או 25-50 טיפות כל 6-8 שעות.',
      sideEffects: 'נדיר אך מסוכן: פגיעה במח העצם (Agranulocytosis), ירידת לחץ דם במתן תוך ורידי.',
      category: 'שיכוך כאב והורדת חום',
    ),
    Medication(
      name: 'אדוויל / נורופן (Ibuprofen)',
      activeIngredient: 'Ibuprofen',
      indications: 'שיכוך כאב קל-בינוני, הורדת חום, טיפול בדלקות.',
      contraindications: 'כיב קיבה (אולקוס), אסתמה המחמירה עם NSAIDs, רגישות ידועה, אי ספיקת כליות.',
      adultDose: '400 מ"ג (2 כדורים של 200) כל 6-8 שעות. חובה לקחת אחרי אוכל.',
      sideEffects: 'כאבי בטן, צרבות, החמרת תפקוד כלייתי בהתייבשות.',
      category: 'שיכוך כאב והורדת חום',
    ),
    Medication(
      name: 'אפיפן (Epipen)',
      activeIngredient: 'Epinephrine',
      indications: 'תגובה אלרגית חריפה (אנפילקסיס) המלווה בקשיי נשימה, נפיחות בשפתיים/לשון, או ירידת ל"ד.',
      contraindications: 'אין התוויות נגד מוחלטות במצב של סכנת חיים.',
      adultDose: '0.3 מ"ג (מזרק צהוב) בהזרקה לשריר הירך (IM). ניתן לחזור על המנה אחרי 5-15 דקות אם אין הטבה.',
      sideEffects: 'דפיקות לב מואצות (טכיקרדיה), רעד, חרדה, חיוורון.',
      category: 'חירום והחייאה',
    ),
    Medication(
      name: 'קל בטן / אימודיום',
      activeIngredient: 'Loperamide',
      indications: 'שלשול חריף ללא חום דם או ריר.',
      contraindications: 'שלשול דמי, חום גבוה (חשד לזיהום חיידקי), חסימת מעיים.',
      adultDose: '2 כדורים (4 מ"ג) מיד, ולאחר מכן כדור אחד (2 מ"ג) אחרי כל יציאה שלשולית. מקסימום 8 ביום.',
      sideEffects: 'עצירות, כאבי בטן עוויתיים, בחילות.',
      category: 'מערכת העיכול',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final allCategories = ['הכל', ..._medications.map((m) => m.category).toSet()];
    
    final filtered = _medications.where((m) {
      final matchesSearch = m.name.toLowerCase().contains(_searchQuery) || 
                            m.activeIngredient.toLowerCase().contains(_searchQuery);
      final matchesCat = _selectedCategory == 'הכל' || m.category == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('QXGO - מדריך תרופות', style: TextStyle(fontWeight: FontWeight.bold)),
            floating: true,
            pinned: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, 0, AppTheme.spacing16, AppTheme.spacing16),
                child: HopalSearchBar(
                  controller: _searchController,
                  placeholder: 'חיפוש לפי שם תרופה או חומר פעיל...',
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing8),
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
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final med = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacing16),
                    child: HopalCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppTheme.spacing8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                  borderRadius: AppTheme.radiusMd,
                                ),
                                child: Icon(LucideIcons.pill, color: AppTheme.primaryGreen),
                              ),
                              const SizedBox(width: AppTheme.spacing12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(med.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                    Text(med.activeIngredient, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                            child: Divider(),
                          ),
                          _buildInfoRow('התוויות', med.indications, LucideIcons.checkCircle2, AppTheme.successGreen),
                          const SizedBox(height: AppTheme.spacing8),
                          _buildInfoRow('התוויות נגד', med.contraindications, LucideIcons.xCircle, AppTheme.criticalRed),
                          const SizedBox(height: AppTheme.spacing8),
                          _buildInfoRow('מינון (מבוגרים)', med.adultDose, LucideIcons.syringe, AppTheme.primaryGreen),
                          const SizedBox(height: AppTheme.spacing8),
                          _buildInfoRow('תופעות לוואי', med.sideEffects, LucideIcons.alertTriangle, AppTheme.warningAmber),
                        ],
                      ),
                    ),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String content, IconData icon, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: AppTheme.spacing8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 14)),
              Text(content, style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

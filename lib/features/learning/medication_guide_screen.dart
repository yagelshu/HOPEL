import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';
import 'package:chopel_app/theme/components/hopal_empty_state.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      contraindications: 'רגישות לאופטלגין, חסר ב-G6PD (רגישות לפול), הריון/הנקה, פגיעה במח העצם.',
      adultDose: '500-1000 מ"ג (1-2 כדורים) או 25-50 טיפות כל 6-8 שעות.',
      sideEffects: 'נדיר אך מסוכן: פגיעה במח העצם (Agranulocytosis), ירידת לחץ דם במתן תוך-ורידי.',
      category: 'שיכוך כאב והורדת חום',
    ),
    Medication(
      name: 'אדוויל / נורופן (Ibuprofen)',
      activeIngredient: 'Ibuprofen (NSAID)',
      indications: 'שיכוך כאב קל-בינוני, הורדת חום, טיפול בדלקות ושרירים.',
      contraindications: 'כיב קיבה (אולקוס), אסתמה המחמירה עם NSAIDs, רגישות ידועה, התייבשות / אי ספיקת כליות.',
      adultDose: '400 מ"ג (2 כדורים של 200) כל 6-8 שעות. חובה לקחת אחרי אוכל.',
      sideEffects: 'כאבי בטן, צרבות, החמרת תפקוד כלייתי בהתייבשות.',
      category: 'שיכוך כאב והורדת חום',
    ),
    Medication(
      name: 'וולטרן / דיקלופנק (Voltaren)',
      activeIngredient: 'Diclofenac (NSAID)',
      indications: 'כאבי גב, שרירים, נקעים ודלקות מפרקים מקומיות (ג\'ל מקומי או כדורים באישור רופא).',
      contraindications: 'רגישות ל-NSAIDs, כיב קיבה פעיל, אי ספיקת כליות או התייבשות קשה.',
      adultDose: 'מריחת ג\'ל 2-3 פעמים ביום על עור שלם (ללא פצע פתוח). פומי — באישור רופא בלבד.',
      sideEffects: 'גירוי מקומי בעור (בג\'ל), צרבת או כאב בטן במתן פומי.',
      category: 'שיכוך כאב והורדת חום',
    ),
    Medication(
      name: 'אפיפן (EpiPen)',
      activeIngredient: 'Epinephrine',
      indications: 'תגובה אלרגית חריפה (אנפילקסיס) המלווה בקשיי נשימה, נפיחות בשפתיים/לשון, או ירידת ל"ד.',
      contraindications: 'אין התוויות נגד מוחלטות במצב של סכנת חיים מיידית.',
      adultDose: '0.3 מ"ג (מזרק צהוב) בהזרקה לשריר הירך החיצוני (IM). ניתן לחזור אחרי 5-15 דקות בהיעדר שיפור.',
      sideEffects: 'דפיקות לב מואצות (טכיקרדיה), רעד, חרדה, חיוורון.',
      category: 'חירום והחייאה',
    ),
    Medication(
      name: 'TXA – הקסאקפרון (פרוטוקול חירום)',
      activeIngredient: 'Tranexamic Acid',
      indications: 'דימום חמור / חשד להלם תת-נפחי בפצוע טראומה תוך עד 3 שעות מרגע הפציעה (בסמכות רופא/פאראמדיק).',
      contraindications: 'מעל 3 שעות מהפציעה, אירוע טרומבו-אמבולי פעיל, רגישות לתרופה.',
      adultDose: '1 גרם בהזרקה/עירוי איטי (במשך 10 דקות) לפי נוהל טראומה גדודי ועדכון רופא.',
      sideEffects: 'בחילה, סחרחורת, ירידת ל"ד בהזרקה מהירה מדי.',
      category: 'חירום והחייאה',
    ),
    Medication(
      name: 'אימודיום (Imodium)',
      activeIngredient: 'Loperamide',
      indications: 'שלשול חריף ללא חום, דם או ריר.',
      contraindications: 'שלשול דמי, חום גבוה (חשד לזיהום חיידקי פולשני), חשד לחסימת מעיים.',
      adultDose: '2 כדורים (4 מ"ג) מיד, ולאחר מכן כדור אחד (2 מ"ג) אחרי כל יציאה שלשולית. מקסימום 8 מ"ג ביום.',
      sideEffects: 'עצירות, כאבי בטן עוויתיים, בחילות.',
      category: 'מערכת העיכול',
    ),
    Medication(
      name: 'זופרן (Zofran – באישור רופא)',
      activeIngredient: 'Ondansetron',
      indications: 'בחילות והקאות קשות המקשות על שתייה ומנוחה.',
      contraindications: 'רגישות ידועה לאונדנסטרון, הארכת מקטע QT ידועה.',
      adultDose: '4 מ"ג (טבליה מסיסה תחת הלשון / במתן רפואי) באישור רופא/נוהל.',
      sideEffects: 'כאב ראש קל, עצירות, עייפות.',
      category: 'מערכת העיכול',
    ),
    Medication(
      name: 'תמיסת מלחים להתייבשות (ORS)',
      activeIngredient: 'Oral Rehydration Salts (NaCl + Glucose)',
      indications: 'התייבשות קלה עד בינונית, החזרת נוזלים ומלחים בשלשולים, הקאות קלות ומאמץ בחום.',
      contraindications: 'חוסר הכרה, הקאות בלתי נשלטות, חסימת מעיים (במצבים אלו נדרש עירוי תוך-ורידי).',
      adultDose: 'המסת שקית אחת בליטר מים (לפי הוראות יצרן) ושתייה בלגימות קטנות לאורך זמן.',
      sideEffects: 'נדיר (בחילה אם נשתה מהר מדי).',
      category: 'מערכת העיכול',
    ),
    Medication(
      name: 'מוקסיפן / אוגמנטין (באישור רופא)',
      activeIngredient: 'Amoxicillin / Amoxicillin-Clavulanate',
      indications: 'טיפול אנטיביוטי בדלקת גרון חיידקית, זיהומי עור, שן או דרכי שתן (באישור רופא בלבד).',
      contraindications: 'רגישות לפניצילין (Penicillin / Amoxicillin), מחלת כבד קודמת משימוש באוגמנטין.',
      adultDose: 'לפי מרשם רופא גדודי בלבד (נפוץ: 500-875 מ"ג כל 8-12 שעות).',
      sideEffects: 'תגובה אלרגית/פריחה, כאבי בטן, שלשול קל.',
      category: 'זיהומים ואנטיביוטיקה',
    ),
    Medication(
      name: 'משחה אנטיביוטית / סילברול (פצעים וכוויות)',
      activeIngredient: 'Mupirocin / Fusidic Acid / Silver Sulfadiazine',
      indications: 'מניעת זיהום מקומי בפצעים שטחיים או כוויות קלות לאחר ניקוי יסודי.',
      contraindications: 'אלרגיה לרכיב הפעיל. שים לב: סילברול אסור ברגישות לסולפה ובחסר G6PD!',
      adultDose: 'מריחה דקה נקייה 2-3 פעמים ביום וחבישה סטרילית.',
      sideEffects: 'גרד או צריבה קלה מקומית.',
      category: 'עור וחיטוי',
    ),
    Medication(
      name: 'פנסטיל ג\'ל / אנטיהיסטמין פומי (לורטדין)',
      activeIngredient: 'Dimetindene / Loratadine',
      indications: 'גרד, עקיצות, פריחה ותגובה אלרגית קלה-מקומית ללא קוצר נשימה.',
      contraindications: 'רגישות ידועה לחומר הפעיל. בתגובה סיסטמית (קוצר נשימה/בצקת) — אפיפן ופינוי מיידי.',
      adultDose: 'לורטדין 10 מ"ג כדור אחד ליום (לא מרדים), או מריחת ג\'ל מקומי 2-4 פעמים ביום.',
      sideEffects: 'יובש בפה, עייפות קלה (נמוך בלורטדין).',
      category: 'עור וחיטוי',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final allCategories = ['הכל', ..._medications.map((m) => m.category).toSet()];

    final filtered = _medications.where((m) {
      final matchesSearch = _searchQuery.isEmpty ||
          m.name.toLowerCase().contains(_searchQuery) ||
          m.activeIngredient.toLowerCase().contains(_searchQuery) ||
          m.indications.toLowerCase().contains(_searchQuery) ||
          m.contraindications.toLowerCase().contains(_searchQuery);
      final matchesCat = _selectedCategory == 'הכל' || m.category == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('מדריך תרופות לשטח', style: TextStyle(fontWeight: FontWeight.bold)),
            floating: true,
            pinned: true,
            leading: IconButton(
              icon: Icon(LucideIcons.arrowRight, color: AppTheme.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, 0, AppTheme.spacing16, AppTheme.spacing16),
                child: HopalSearchBar(
                  controller: _searchController,
                  placeholder: 'חפש תרופה, חומר פעיל, תלונה או G6PD...',
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
                      label: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? AppTheme.onPrimaryGreen : AppTheme.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      checkmarkColor: AppTheme.onPrimaryGreen,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategory = cat);
                      },
                      backgroundColor: AppTheme.backgroundSecondary,
                      selectedColor: AppTheme.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: isSelected ? AppTheme.primaryGreen : AppTheme.borderSubtle),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (filtered.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: AppTheme.spacing48),
                child: HopalEmptyState(
                  icon: LucideIcons.pill,
                  title: 'לא נמצאה תרופה תואמת',
                  subtitle: 'נסה לחפש בשם מסחרי, חומר פעיל או קטגוריה אחרת.',
                ),
              ),
            )
          else
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
                                    color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                                    borderRadius: AppTheme.radiusMd,
                                  ),
                                  child: Icon(LucideIcons.pill, color: AppTheme.primaryGreen),
                                ),
                                const SizedBox(width: AppTheme.spacing12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(med.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                      Text(med.activeIngredient, style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary)),
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

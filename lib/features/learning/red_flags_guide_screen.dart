import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';
import 'package:chopel_app/theme/components/hopal_search_bar.dart';

class RedFlagTopic {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String urgencyBadge;
  final List<String> redFlags;
  final List<String> mandatoryChecks;
  final String immediateAction;

  const RedFlagTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.urgencyBadge,
    required this.redFlags,
    required this.mandatoryChecks,
    required this.immediateAction,
  });
}

class RedFlagsGuideScreen extends StatefulWidget {
  final String? initialTopicId;

  const RedFlagsGuideScreen({super.key, this.initialTopicId});

  static const List<RedFlagTopic> topics = [
    RedFlagTopic(
      id: 'abdomen_gastro',
      title: 'כאבי בטן, הקאות ושלשולים (בטן חריפה והתייבשות)',
      subtitle: 'זיהוי סימני התייבשות חמורה ובטן חריפה הדורשים בדיקת רופא/מט"ב',
      category: 'בטן ומערכת העיכול',
      urgencyBadge: 'בדיקת מט"ב בחשד',
      redFlags: [
        'בטן קשה למגע ("קרשית") או כאב חריף וממוקד בבטן ימנית תחתונה המוחמר בתזוזה/קפיצה.',
        'הקאות חוזרות ובלתי פוסקות שאינן מאפשרות לחייל לשתות ולהחזיר נוזלים.',
        'דם טרי בצואה או שלשול דמי המלווה בחום גבוה (מעל 38.5°C) – אין לתת אימודיום במצב זה!',
        'סימני התייבשות משמעותית: דופק מהיר במנוחה (טכיקרדיה), סחרחורת בעמידה, יובש קיצוני בפה ומיעוט שתן.',
      ],
      mandatoryChecks: [
        'מדדים חיוניים מלאים: דופק, לחץ דם, חום וסטורציה.',
        'מישוש עדין של הבטן (רכה או קשה/רגישה) ותשאול על יכולת שתייה ומתן שתן.',
      ],
      immediateAction:
          'בכאב בטן חריף עם בטן קשה – להימנע ממתן אוכל ומשככי כאבים הממסכים את הבדיקה, להשלים מדדים ולפנות לבדיקת מט"ב/רופא.',
    ),
    RedFlagTopic(
      id: 'throat_airway',
      title: 'כאב גרון ודרכי נשימה עליונות',
      subtitle: 'הבחנה בין דלקת גרון רגילה לאבצס פרי-טונסילרי ואיום על נתיב אוויר',
      category: 'נשימה וא.א.ג',
      urgencyBadge: 'סכנת נתיב אוויר',
      redFlags: [
        'קושי בבליעת רוק או ריור (החייל לא מסוגל לבלוע את הרוק של עצמו).',
        'טריזמוס (Trismus) – קושי או כאב חד בפתיחת הפה (פחות מ-3 אצבעות).',
        'קול עמום ("Hot Potato Voice" – נשמע כאילו מדבר עם תפוח אדמה חם בפה) או סטרידור.',
        'אסימטריה בולטת בחך או סטיית הענבל (Uvula) לצד אחד (חשד לאבצס פרי-טונסילרי).',
      ],
      mandatoryChecks: [
        'הסתכלות ללוע עם פנס: בדיקת סימטריה של השקדים והענבל ויכולת פתיחת פה מלאה.',
        'מדידת חום, דופק וסטורציה באוויר חדר.',
        'בדיקת רגישות ונפיחות בצוואר קדמי וקשריות לימפה.',
      ],
      immediateAction:
          'להושיב את החייל (לא להשכיב!), להימנע מגירוי אגרסיבי של הלוע, ולפנות בדחיפות לבדיקת מט"ב/מיון א.א.ג.',
    ),
    RedFlagTopic(
      id: 'chest_dyspnea',
      title: 'כאב חזה וקוצר נשימה',
      subtitle: 'שלילת מיוקרדיטיס, תסמונת כלילית, חזה אוויר עצמוני ותסחיף ריאתי',
      category: 'לב ונשימה',
      urgencyBadge: 'חירום לבבי/נשימתי',
      redFlags: [
        'כאב חזה לוחץ/שורף המקרין ליד שמאל, לסת, גב או רום הבטן, או מלווה בהזעה קרה ובחילה.',
        'כאב חזה המופיע בזמן מאמץ או בימים שלאחר מחלת חום ויראלית (חשד למיוקרדיטיס/פריקרדיטיס בחיילים צעירים!).',
        'כאב חזה חד ופתאומי המוחמר בשאיפה עמוקה עם קוצר נשימה (חשד לחזה אוויר עצמוני – שכיח בגברים צעירים גבוהים ורזים).',
        'סטורציה מתחת ל-94% באוויר חדר, קוצר נשימה במנוחה או דופק מהיר לא מוסבר (מעל 110 במנוחה).',
      ],
      mandatoryChecks: [
        'מדדים חיוניים מלאים: ל"ד בשתי ידיים במידת האפשר, דופק (קצב וסדירות), סטורציה ומספר נשימות.',
        'תשאול על מחלת חום בשבועיים האחרונים (קריטי לשלילת מיוקרדיטיס לפני חזרה למאמץ!).',
      ],
      immediateAction:
          'מנוחה מוחלטת בישיבה, איסור מוחלט על כל מאמץ פיזי, חיבור לחמצן במידה וסטורציה נמוכה, ודיווח מיידי למט"ב לביצוע א.ק.ג ופינוי.',
    ),
    RedFlagTopic(
      id: 'heat_injury',
      title: 'פגיעות חום והתייבשות במאמץ',
      subtitle: 'הגבול הדק והקטלני בין תשישות חום למכת חום (Heat Stroke)',
      category: 'אקלים ומאמץ',
      urgencyBadge: 'קירור מיידי בשטח',
      redFlags: [
        'כל שינוי במצב ההכרה או בהתנהגות: בלבול, אפתיות, אי-שקט, דיבור לא ברור או חוסר התמצאות בזמן ובמקום.',
        'אטקסיה (הליכה מתנדנדת, חוסר יציבות או קריסה במהלך/אחרי מאמץ).',
        'טמפרטורת ליבה (רקטלית) מעל 40.0°C (שים לב: במכת חום העור של החייל יכול להיות מזיע מאוד!).',
        'הקאות חוזרות או פרכוסים.',
      ],
      mandatoryChecks: [
        'הערכת הכרה והתמצאות (שם, מיקום, תאריך, מה המשימה כרגע).',
        'מדידת דופק, ל"ד ובחשד לפגיעת חום משמעותית – מדידת חום מהימנה לפי נוהל קרפ"ר.',
      ],
      immediateAction:
          'בחשד למכת חום: "קודם מקררים ואז מפנים!" – הפשטה מלאה בצל, שפיכת מים קרים בכמויות גדולות + נפנוף אוויר רציף, עירוי נוזלים ודיווח חירום למט"ב.',
    ),
    RedFlagTopic(
      id: 'headache_head_trauma',
      title: 'חבלת ראש וכאבי ראש חריגים',
      subtitle: 'סימני לחץ תוך-גולגולתי מוגבר (ICP) ודלקת קרום המוח',
      category: 'נוירולוגיה וטראומה',
      urgencyBadge: 'דגל אדום נוירולוגי',
      redFlags: [
        'אובדן הכרה (אפילו לשניות בודדות), אמנזיה (שכחה של האירוע) או בלבול לאחר מכה בראש.',
        'הקאות חוזרות (2 ומעלה) או כאב ראש ההולך ומחמיר בעוצמתו.',
        'כאב ראש פתאומי בעוצמה מקסימלית ("רעם ביום בהיר") או כאב ראש שמעיר משינה.',
        'חום + כאב ראש + קשיון עורף או פריחה נקודתית שלא נעלמת בלחיצה (פטכיות – חשד למנינגוקוק!).',
        'הפרעות ראייה (ראייה כפולה/מטושטשת), אסימטריה באישונים או חולשה/נימול בגפיים.',
      ],
      mandatoryChecks: [
        'בדיקת אישונים (שווים ומגיבים לאור), כוח גס ב-4 גפיים וחיוך סימטרי.',
        'בדיקת קשיון עורף (יכולת הצמדת סנטר לחזה) ובדיקת העור לפריחה פטכיאלית בחייל עם חום וכאב ראש.',
      ],
      immediateAction:
          'השגחה רציפה (לא להשאיר את החייל לבד באוהל!), דיווח מיידי למט"ב ופינוי לבדיקת רופא/מיון.',
    ),
    RedFlagTopic(
      id: 'anaphylaxis_allergy',
      title: 'תגובה אלרגית חריפה / עקיצות (אנפילקסיס)',
      subtitle: 'זיהוי מעורבות רב-מערכתית והזרקת אפיפן מצילת חיים',
      category: 'אלרגיה וחירום',
      urgencyBadge: 'אפיפן מיד!',
      redFlags: [
        'פריחה/גרד עורי המלווה בקוצר נשימה, צפצופים, צרידות או תחושת "גוש בגרון".',
        'נפיחות מהירה של השפתיים, הלשון או העפעפיים (אנגיואדמה).',
        'תגובה אלרגית המלווה בסחרחורת, חולשה קיצונית, ירידת ל"ד או כאבי בטן/הקאות.',
      ],
      mandatoryChecks: [
        'בדיקת נתיב אוויר (צרידות/נפיחות בלשון), סטורציה, דופק ולחץ דם.',
        'תשאול מהיר על חשיפה למזון, תרופה חדשה או עקיצת דבורה/צרעה.',
      ],
      immediateAction:
          'הזרקת אפיפן (EpiPen) מיידית לשריר הירך החיצוני (ניתן גם דרך המדי!), השכבה עם רגליים מורמות (אלא אם מתקשה לנשום), חמצן ופינוי דחוף.',
    ),
    RedFlagTopic(
      id: 'back_limbs_neuro',
      title: 'כאבי גב וגפיים (דגלים אדומים נוירולוגיים ווסקולריים)',
      subtitle: 'מתי כאב גב או פציעת גפה דורשים פינוי דחוף ולא רק משככי כאבים',
      category: 'אורתופדיה ונוירולוגיה',
      urgencyBadge: 'בדיקה נוירולוגית',
      redFlags: [
        'כאב גב המלווה בקושי במתן שתן (אצירת שתן) או אי-שליטה בסוגרים (חשד לתסמונת זנב הסוס – חירום כירורגי!).',
        'ירידה בתחושה באזור המפשעה/ישבן ("הרדמה בצורת אוכף") או חולשה מוטורית חדשה ברגל (כגון צניחת כף רגל – Drop Foot).',
        'כאב קיצוני בגפה לאחר חבלה/מאמץ שאינו פרופורציונלי לממצא ומוחמר במתיחה פסיבית של האצבעות (חשד לתסמונת מדור – Compartment Syndrome).',
        'גפה חיוורת, קרה, ללא דופק פריפרי או עם אובדן תחושה.',
      ],
      mandatoryChecks: [
        'בדיקת הליכה על קצות האצבעות ועל העקבים (בודק שורשי עצב L4-S1).',
        'בדיקת דופק דיסטלי, מילוי קפילרי, תחושה ותנועה פעילה של האצבעות.',
      ],
      immediateAction:
          'קיבוע עדין במנח נוח, שחרור חבישות לוחצות (בחשד לתסמונת מדור), והפניה דחופה למט"ב/מיון.',
    ),
  ];

  @override
  State<RedFlagsGuideScreen> createState() => _RedFlagsGuideScreenState();
}

class _RedFlagsGuideScreenState extends State<RedFlagsGuideScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'הכל';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['הכל', ...RedFlagsGuideScreen.topics.map((t) => t.category).toSet()];

    final filtered = RedFlagsGuideScreen.topics.where((topic) {
      final matchesCat = _selectedCategory == 'הכל' || topic.category == _selectedCategory;
      if (!matchesCat) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return topic.title.toLowerCase().contains(q) ||
          topic.subtitle.toLowerCase().contains(q) ||
          topic.redFlags.any((f) => f.toLowerCase().contains(q)) ||
          topic.immediateAction.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('דגלים אדומים בשטח (Red Flags)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, 4, AppTheme.spacing16, 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.criticalRed.withValues(alpha: 0.12),
                borderRadius: AppTheme.radiusMd,
                border: Border.all(color: AppTheme.criticalRed.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.shieldAlert, color: AppTheme.criticalRed, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'מדריך כיס קליני לחופ"ל ולחובש: סימני האזהרה שמחייבים בדיקת מט"ב/רופא או פינוי מיידי – לפני שמשחררים חייל לאוהל.',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 12.5, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
            child: HopalSearchBar(
              controller: _searchController,
              placeholder: 'חפש תלונה או סימן אזהרה (למשל: בטן, גרון, חום, אפיפן)...',
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: 8),
            child: Row(
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    selectedColor: AppTheme.criticalRed.withValues(alpha: 0.2),
                    backgroundColor: AppTheme.backgroundSecondary,
                    checkmarkColor: AppTheme.criticalRed,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.criticalRed : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppTheme.criticalRed : AppTheme.borderSubtle,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, 4, AppTheme.spacing16, 40),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final topic = filtered[index];
                final initiallyExpanded = widget.initialTopicId == topic.id || index == 0;
                return _buildTopicCard(topic, initiallyExpanded: initiallyExpanded);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(RedFlagTopic topic, {required bool initiallyExpanded}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: HopalCard(
        borderColor: AppTheme.criticalRed.withValues(alpha: 0.35),
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            tilePadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: 6),
            childrenPadding: const EdgeInsets.fromLTRB(AppTheme.spacing16, 0, AppTheme.spacing16, AppTheme.spacing16),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.criticalRed.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(LucideIcons.siren, color: AppTheme.criticalRed, size: 20),
            ),
            title: Text(
              topic.title,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                topic.subtitle,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),
            children: [
              Divider(color: AppTheme.borderSubtle, height: 16),
              Row(
                children: [
                  Icon(LucideIcons.alertTriangle, size: 15, color: AppTheme.criticalRed),
                  const SizedBox(width: 6),
                  Text(
                    'דגלים אדומים – מתי לחשוד בסכנה מיידית:',
                    style: TextStyle(
                      color: AppTheme.criticalRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...topic.redFlags.map(
                (flag) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: AppTheme.criticalRed, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          flag,
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(LucideIcons.stethoscope, size: 15, color: AppTheme.infoBlue),
                  const SizedBox(width: 6),
                  Text(
                    'בדיקות חובה לחובש בשטח:',
                    style: TextStyle(
                      color: AppTheme.infoBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...topic.mandatoryChecks.map(
                (check) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('✓ ', style: TextStyle(color: AppTheme.infoBlue, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          check,
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: AppTheme.radiusMd,
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.zap, size: 16, color: AppTheme.primaryGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'פעולה מיידית: ${topic.immediateAction}',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


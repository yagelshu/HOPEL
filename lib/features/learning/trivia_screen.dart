import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';

class TriviaScreen extends ConsumerStatefulWidget {
  const TriviaScreen({super.key});

  @override
  ConsumerState<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends ConsumerState<TriviaScreen> {
  int _score = 0;
  int _currentQuestionIndex = 0;
  bool _answered = false;
  int? _selectedAnswerIndex;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'פצוע מגיע עם דופק 120 ולחץ דם 90/60 לאחר הדיפה מפיצוץ. מהי הפעולה הראשונה?',
      'options': [
        'מתן נוזלים לווריד',
        'הנחת חוסם עורקים אוטומטית בכל גפה',
        'בדיקת נתיב אוויר והנשמה תחילה',
        'סריקה לזיהוי מקור דימום פורץ ועצירתו מיד',
      ],
      'correctIndex': 3,
      'explanation': 'לפי סכמת X-CARE / PHTLS, יש לזהות ולעצור דימומים פורצים מסכני חיים לפני כל פעולה אחרת.',
    },
    {
      'question': 'מהו הסימן המוקדם ביותר להתייבשות / הלם תת-נפחי?',
      'options': [
        'ירידה בלחץ דם',
        'טכיקרדיה (דופק מהיר)',
        'איבוד הכרה',
        'ירידה בסטורציה ל-80%',
      ],
      'correctIndex': 1,
      'explanation': 'הגוף מפצה על חוסר נוזלים או אובדן דם תחילה בעליית דופק. ירידת לחץ דם היא סימן מאוחר המעיד על קריסת פיצוי.',
    },
    {
      'question': 'איזו פעולה אסור לבצע בעת טיפול בכווית חום שטחית?',
      'options': [
        'שטיפה במים זורמים קרירים',
        'הסרת בגדים ותכשיטים שאינם דבוקים לכוויה',
        'מריחת משחת שיניים או קרח ישירות',
        'כיסוי בחבישה נקייה שאינה נדבקת',
      ],
      'correctIndex': 2,
      'explanation': 'קרח ישיר או משחות ביתיות עלולים לגרום לנזק רקמתי נוסף או לזיהום. קירור עדין במים פושרים/קרירים וחבישה נקייה הם הטיפול הנכון.',
    },
    {
      'question': 'מה המינון המקובל של קטמין למתן תוך-שרירי (IM) כאלחוש לפצוע טראומה?',
      'options': [
        '0.5 מ"ג לק"ג',
        '2 מ"ג לק"ג',
        '5 מ"ג לק"ג',
        '10 מ"ג לק"ג',
      ],
      'correctIndex': 2,
      'explanation': 'בסמכות מתן קטמין לשריר (IM) לאלחוש/ניתוק בפצוע טראומה, המינון המקובל לפי פרוטוקול הוא כ-5 מ"ג לק"ג (בד"כ עד 400 מ"ג בפצוע במשקל 80 ק"ג).',
    },
    {
      'question': 'מתי מתחיל להיווצר נזק איסכמי משמעותי לגפה בעקבות השארת חסם עורקים?',
      'options': [
        'אחרי 15 דקות בלבד',
        'החל מ-2 שעות ובעיקר מעל 4-6 שעות',
        'אחרי 18 שעות',
        'אין שום סכנה של נזק איסכמי מחסם עורקים',
      ],
      'correctIndex': 1,
      'explanation': 'נזק איסכמי מתחיל להתפתח מעבר לכ-2 שעות והופך לבלתי הפיך בעיקר סביב 4-6 שעות; חשוב לתעד שעת הנחה מדויקת ולהתייעץ עם רופא על המרת ח"ע במידת הצורך.',
    },
    {
      'question': 'איזה מהבאים הוא התווית נגד ברורה למתן מורפין בשטח?',
      'options': [
        'שבר פתוח בגפה עם לחץ דם תקין',
        'לחץ דם סיסטולי נמוך מ-90 ממ"כ / הלם',
        'כוויה מקומית ביד',
        'הפצוע בהכרה מלאה ומתמצא',
      ],
      'correctIndex': 1,
      'explanation': 'מורפין עלול לגרום להרחבת כלי דם ולירידת לחץ דם ודיכוי נשימתי, ולכן אסור במתן לפצועים בהלם או בל"ד סיסטולי נמוך מ-90.',
    },
    {
      'question': 'באיזה מצב חירום יש לבצע ניקוז מחט לחזה (AW / Needle Decompression)?',
      'options': [
        'חזה אוויר בלחץ (Tension Pneumothorax)',
        'דימום פנימי בבטן',
        'דום לב ללא טראומה',
        'התייבשות קלה אחרי מסע',
      ],
      'correctIndex': 0,
      'explanation': 'ניקוז חזה במחט נועד לשחרר אוויר לכוד תחת לחץ בחלל הפלאורלי המונע מהריאה להתרחב ולוחץ על כלי הדם הגדולים.',
    },
  ];

  late List<Map<String, dynamic>> _sessionQuestions;

  @override
  void initState() {
    super.initState();
    final shuffled = List<Map<String, dynamic>>.from(_questions)..shuffle(Random());
    _sessionQuestions = shuffled.take(3).toList();
  }

  void _submitAnswer(int index) {
    if (_answered) return;

    setState(() {
      _selectedAnswerIndex = index;
      _answered = true;
      if (index == _sessionQuestions[_currentQuestionIndex]['correctIndex']) {
        _score += 10;
        HopalFeedback.showSuccess(context, 'תשובה נכונה! צברת 10 נקודות');
      } else {
        HopalFeedback.showError(context, 'תשובה שגויה.');
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      if (_currentQuestionIndex < _sessionQuestions.length - 1) {
        _currentQuestionIndex++;
        _answered = false;
        _selectedAnswerIndex = null;
      } else {
        _showCompletionDialog();
      }
    });
  }

  Future<void> _showCompletionDialog() async {
    if (_score > 0) {
      await AuthService().awardCompetencePoints(_score);
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundSecondary,
        title: Text('תרגול יומי הושלם!', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'סיימת את התרגול היומי.\nצברת $_score נקודות כשירות!',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.45),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: AppTheme.onPrimaryGreen,
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close screen
            },
            child: const Text('מעולה', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = _sessionQuestions[_currentQuestionIndex];
    final options = currentQ['options'] as List<String>;

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text('תרגול יומי לחובש', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowRight, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24, vertical: AppTheme.spacing16),
              child: _buildCompetenceProgress(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, AppTheme.spacing16, AppTheme.spacing16, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'שאלה ${_currentQuestionIndex + 1} מתוך ${_sessionQuestions.length}',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    HopalCard(
                      padding: const EdgeInsets.all(AppTheme.spacing24),
                      child: Text(
                        currentQ['question'],
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing32),
                    ...List.generate(options.length, (index) {
                      final isSelected = _selectedAnswerIndex == index;
                      final isCorrect = index == currentQ['correctIndex'];

                      Color bgColor = AppTheme.backgroundSecondary;
                      Color borderColor = AppTheme.borderSubtle;

                      if (_answered) {
                        if (isCorrect) {
                          bgColor = AppTheme.successGreen.withValues(alpha: 0.2);
                          borderColor = AppTheme.successGreen;
                        } else if (isSelected) {
                          bgColor = AppTheme.criticalRed.withValues(alpha: 0.2);
                          borderColor = AppTheme.criticalRed;
                        }
                      } else if (isSelected) {
                        borderColor = AppTheme.primaryGreen;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spacing16),
                        child: InkWell(
                          onTap: () => _submitAnswer(index),
                          borderRadius: AppTheme.radiusMd,
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.spacing16),
                            decoration: BoxDecoration(
                              color: bgColor,
                              border: Border.all(color: borderColor, width: 2),
                              borderRadius: AppTheme.radiusMd,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    options[index],
                                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                                  ),
                                ),
                                if (_answered && isCorrect)
                                  Icon(LucideIcons.checkCircle2, color: AppTheme.successGreen)
                                else if (_answered && isSelected && !isCorrect)
                                  Icon(LucideIcons.xCircle, color: AppTheme.criticalRed),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: AppTheme.spacing24),
                    if (_answered) ...[
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacing16),
                        decoration: BoxDecoration(
                          color: AppTheme.infoBlue.withValues(alpha: 0.1),
                          borderRadius: AppTheme.radiusMd,
                          border: Border.all(color: AppTheme.infoBlue.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(LucideIcons.info, color: AppTheme.infoBlue, size: 20),
                                const SizedBox(width: 8),
                                Text('הסבר קצר', style: TextStyle(color: AppTheme.infoBlue, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentQ['explanation'],
                              style: TextStyle(color: AppTheme.textPrimary, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing24),
                      HopalButton(
                        label: _currentQuestionIndex == _sessionQuestions.length - 1 ? 'סיום ותיעוד נקודות' : 'הבא',
                        onPressed: _nextQuestion,
                        isExpanded: true,
                        icon: LucideIcons.arrowLeft,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetenceProgress() {
    final user = AuthService().currentUser;
    final points = (user?.competencePoints ?? 0) + _score;
    const goal = 100;
    final progress = (points / goal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: AppTheme.radiusLg,
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('כשירות מבצעית', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
              Text('$points / $goal נק\'', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.backgroundTertiary,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            points >= goal
                ? 'הגעת ליעד הכשירות המרבי! המשך לתרגל כדי לשמור עליו.'
                : 'ענה על שאלות כדי להעלות את נקודות הכשירות שלך.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

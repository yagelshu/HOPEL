import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:chopel_app/core/network/sync_engine.dart';

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
        'מתן נוזלים לוריד',
        'הנחת חוסם עורקים',
        'בדיקת נתיב אוויר והנשמה',
        'סריקה לזיהוי מקור דימום וטיפול בו'
      ],
      'correctIndex': 3,
      'explanation': 'לפי סכמת PHTLS, יש לעצור דימומים פורצים (M/C) לפני כל פעולה אחרת.',
    },
    {
      'question': 'מהו הסימן המוקדם ביותר להתייבשות / הלם תת-נפחי?',
      'options': [
        'ירידה בלחץ דם',
        'טכיקרדיה (דופק מהיר)',
        'איבוד הכרה',
        'חיוורון והזעה'
      ],
      'correctIndex': 1,
      'explanation': 'הגוף מפצה על חוסר נוזלים תחילה בעליית דופק. ירידת לחץ דם היא סימן מאוחר יחסית המעיד על קריסה מערכתית.',
    },
    {
      'question': 'איזו פעולה אסור לבצע בעת טיפול בכוויות חום שטחית?',
      'options': [
        'שטיפה במים זורמים קרירים',
        'הסרת בגדים שאינם דבוקים לכויה',
        'מריחת משחת שיניים או קרח ישירות',
        'כיסוי בחבישה סטרילית'
      ],
      'correctIndex': 2,
      'explanation': 'קרח או משחות סבתא עלולים לגרום לנזק רקמתי נוסף או זיהום. מים קרירים וחבישה הם הטיפול המומלץ.',
    },
    {
      'question': 'מה המינון המקסימלי של קטמין למתן תוך שרירי (IM) בפצוע שוקל 80 ק"ג?',
      'options': [
        '50 מ"ג',
        '250 מ"ג',
        '400 מ"ג (5 מ"ג לק"ג)',
        '500 מ"ג'
      ],
      'correctIndex': 2,
      'explanation': 'המינון של קטמין לשריר למטרות אלחוש וניתוק הוא 5 מ"ג לק"ג.',
    },
    {
      'question': 'כמה זמן מרגע פציעת חוסם עורקים מתחיל להיווצר נזק איסכמי בלתי הפיך לגפה?',
      'options': [
        'שעה אחת',
        'בין 4 ל-6 שעות',
        '12 שעות',
        '24 שעות'
      ],
      'correctIndex': 1,
      'explanation': 'נזק רקמתי בלתי הפיך מהעדר אספקת דם בגלל חסם עורקים מתחיל לאחר כ-4 עד 6 שעות.',
    },
    {
      'question': 'איזה מהבאים הוא התווית נגד למתן מורפין?',
      'options': [
        'כאב עצבני',
        'לחץ דם סיסטולי נמוך מ-90',
        'פציעה חודרת בבטן',
        'קטיעה של גפה'
      ],
      'correctIndex': 1,
      'explanation': 'מורפין מרחיב כלי דם ועלול להוריד את לחץ הדם עוד יותר, ולכן מסוכן בפצועים בהלם תת-נפחי.',
    },
    {
      'question': 'באיזה מצב יש לבצע מחט חזה (AW) לפצוע טראומה?',
      'options': [
        'חזה אוויר בלחץ (Tension Pneumothorax)',
        'דימום פנימי בבטן',
        'דום לב',
        'חוסר הכרה מסיבה לא ידועה'
      ],
      'correctIndex': 0,
      'explanation': 'מחט חזה נועדה לשחרר אוויר שהצטבר בלחץ בחלל הפלאורלי ומונע מהריאה להתרחב.',
    }
  ];

  late List<Map<String, dynamic>> _sessionQuestions;

  @override
  void initState() {
    super.initState();
    _questions.shuffle(Random());
    _sessionQuestions = _questions.take(3).toList();
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
        // End of trivia
        _showCompletionDialog();
      }
    });
  }

  Future<void> _showCompletionDialog() async {
    // Add points to user
    final authService = AuthService();
    final user = authService.currentUser;
    if (user != null && _score > 0) {
      try {
        // Queue the points update to ensure it syncs offline
        await Supabase.instance.client.from('users').update({
          'competence_points': user.competencePoints + _score,
        }).eq('id', user.id);
        authService.updateCompetencePoints(_score);
      } catch (e) {
        // Handle error gracefully if offline
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundSecondary,
        title: Text('תרגול יומי הושלם!', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('סיימת את התרגול היומי.\nצברת $_score נקודות כשירות!', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close screen
            },
            child: Text('מעולה', style: TextStyle(color: AppTheme.primaryGreen)),
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
        title: Text('תרגול יומי 🧠', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
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
                          bgColor = AppTheme.warningAmber.withValues(alpha: 0.2);
                          borderColor = AppTheme.warningAmber;
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
                                  Icon(LucideIcons.xCircle, color: AppTheme.warningAmber),
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
                                SizedBox(width: 8),
                                Text('הסבר קצר', style: TextStyle(color: AppTheme.infoBlue, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 150),
                              child: SingleChildScrollView(
                                child: Text(currentQ['explanation'], style: TextStyle(color: AppTheme.textPrimary)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing24),
                      HopalButton(
                        label: 'הבא',
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
            points >= goal ? 'הגעת ליעד הכשירות המרבי! המשך לתרגל כדי לשמור עליו.' : 'ענה על שאלות כדי להעלות את נקודות הכשירות שלך.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

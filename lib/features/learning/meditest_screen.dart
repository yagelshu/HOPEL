import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

class MeditestScreen extends StatefulWidget {
  const MeditestScreen({super.key});

  @override
  State<MeditestScreen> createState() => _MeditestScreenState();
}

class _MeditestScreenState extends State<MeditestScreen> {
  static const List<QuizQuestion> _questionsBank = [
    QuizQuestion(
      question: 'באיזה מיקום מניחים חסם עורקים תחת אש (Care Under Fire)?',
      options: [
        'מעט מעל הפצע בלבד',
        'הכי גבוה והכי חזק על הגפה (High & Tight)',
        'מעל מפרק הברך או המרפק בלבד',
        'ישירות על הפצע',
      ],
      correctIndex: 1,
      explanation: 'תחת אש מניחים חסם עורקים הכי גבוה והכי חזק (High & Tight) על הגפה הפגועה לעצירה מהירה ובטוחה של דימום קטלני.',
    ),
    QuizQuestion(
      question: 'באילו מקרים אסור לתת אופטלגין?',
      options: [
        'כאב ויסרלי (עוויתי)',
        'פצוע עם חום גבוה',
        'חסר באנזים G6PD (רגישות לפול)',
        'פצוע לאחר נקע בקרסול',
      ],
      correctIndex: 2,
      explanation: 'אופטלגין (Dipyrone) אסור לבעלי חסר באנזים G6PD מחשש לתגובת פירוק כדוריות דם אדומות (המוליזה).',
    ),
    QuizQuestion(
      question: 'מהו קצב העיסויים הנדרש בהחייאת מבוגר?',
      options: [
        '60-80 לדקה',
        '80-100 לדקה',
        '100-120 לדקה',
        '120-140 לדקה',
      ],
      correctIndex: 2,
      explanation: 'קצב העיסויים המומלץ לפי הנחיות החייאה הוא 100-120 עיסויים בדקה, בעומק של כ-5-6 ס"מ.',
    ),
    QuizQuestion(
      question: 'כמה מ"ג אדרנלין יש במזרק אפיפן צהוב (למבוגר)?',
      options: [
        '0.15 מ"ג',
        '0.3 מ"ג',
        '0.5 מ"ג',
        '1.0 מ"ג',
      ],
      correctIndex: 1,
      explanation: 'מזרק אפיפן צהוב (מבוגר) מכיל 0.3 מ"ג אדרנלין. מזרק ירוק (ילדים) מכיל 0.15 מ"ג.',
    ),
    QuizQuestion(
      question: 'מהו חלון הזמן למתן TXA (הקסאקפרון) לפצוע טראומה עם דימום קשה?',
      options: [
        'עד 15 דקות מרגע הפציעה בלבד',
        'תוך עד 3 שעות מרגע הפציעה',
        'לאחר 6 שעות מרגע הפציעה',
        'רק לאחר כניסה לחדר ניתוח',
      ],
      correctIndex: 1,
      explanation: 'מתן TXA יעיל ומותר בפרוטוקול בתוך 3 שעות מרגע הפציעה (מוקדם ככל הניתן). מעל 3 שעות אינו יעיל ואף עלול להזיק.',
    ),
    QuizQuestion(
      question: 'מהו הטיפול המיידי המתאים לחייל בהכרה מלאה עם סימני התייבשות קלה?',
      options: [
        'העברת החייל לצל, קירור והחזרת נוזלים/מלחים בשתייה',
        'מתן מורפין מניעתי',
        'כיסוי מיידי בשמיכת חימום',
        'מניעת שתייה במשך 4 שעות',
      ],
      correctIndex: 0,
      explanation: 'בהתייבשות קלה ללא הקאות בלתי נשלטות או ירידה בהכרה, העברה לצל, הורדת עומס ושתייה (עדיף עם ORS) הן הטיפול הנכון.',
    ),
    QuizQuestion(
      question: 'מהם שני המאפיינים המרכזיים המבדילים מכת חום מסכנת חיים מהתייבשות רגילה?',
      options: [
        'יובש בפה ועייפות קלה בלבד',
        'חום גוף ליבה גבוה (בד"כ מעל 40°C) + שינוי במצב ההכרה / בלבול',
        'צבע שתן צהוב כהה בלבד',
        'כאב שרירים ברגליים בלבד',
      ],
      correctIndex: 1,
      explanation: 'במכת חום מופיעה פגיעה במערכת העצבים המרכזית (בלבול, אפתיה, אי-שקט, פרכוסים או ערפול הכרה) יחד עם חום ליבה גבוה — חובה קירור מיידי ופינוי דחוף.',
    ),
    QuizQuestion(
      question: 'מהי מטרת תחבושת אטימה לחזה (כגון אשרמן / HyFin)?',
      options: [
        'עצירת דימום פורץ בגפה עליונה',
        'קיבוע שבר פתוח',
        'אטימת פצע חודר בבית החזה למניעת כניסת אוויר לחלל הפלאורלי',
        'חבישת כוויות שטחיות בגב',
      ],
      correctIndex: 2,
      explanation: 'תחבושת אטימה (עם שסתום או מאווררת) אוטמת פצע חזה פתוח ומונעת התפתחות חזה אוויר בלחץ.',
    ),
  ];

  late List<QuizQuestion> _sessionQuestions;
  int _currentIndex = 0;
  int? _selectedIndex;
  bool _showExplanation = false;
  int _score = 0;
  int _earnedPoints = 0;
  bool _quizFinished = false;

  @override
  void initState() {
    super.initState();
    _sessionQuestions = List<QuizQuestion>.from(_questionsBank)..shuffle(Random());
  }

  void _submitAnswer() {
    if (_selectedIndex == null) return;

    final isCorrect = _selectedIndex == _sessionQuestions[_currentIndex].correctIndex;
    if (isCorrect) _score++;

    setState(() {
      _showExplanation = true;
    });
  }

  Future<void> _nextQuestion() async {
    if (_currentIndex < _sessionQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
        _showExplanation = false;
      });
    } else {
      final pts = _score * 5;
      if (pts > 0) {
        await AuthService().awardCompetencePoints(pts);
      }
      if (!mounted) return;
      setState(() {
        _earnedPoints = pts;
        _quizFinished = true;
      });
    }
  }

  void _restartQuiz() {
    setState(() {
      _sessionQuestions = List<QuizQuestion>.from(_questionsBank)..shuffle(Random());
      _currentIndex = 0;
      _selectedIndex = null;
      _showExplanation = false;
      _score = 0;
      _earnedPoints = 0;
      _quizFinished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_quizFinished) {
      return _buildResultsScreen();
    }

    final question = _sessionQuestions[_currentIndex];

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Meditest - ריענון חובשים', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowRight, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16).copyWith(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: (_currentIndex + 1) / _sessionQuestions.length,
                backgroundColor: AppTheme.backgroundSecondary,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              ),
              const SizedBox(height: AppTheme.spacing24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'שאלה ${_currentIndex + 1} מתוך ${_sessionQuestions.length}',
                        style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                      Text(
                        question.question,
                        style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, height: 1.35),
                      ),
                      const SizedBox(height: AppTheme.spacing32),
                      ...List.generate(question.options.length, (index) {
                        final isSelected = _selectedIndex == index;
                        final isCorrect = index == question.correctIndex;

                        Color borderColor = isSelected ? AppTheme.primaryGreen : AppTheme.borderSubtle;
                        Color bgColor = isSelected ? AppTheme.primaryGreen.withValues(alpha: 0.1) : AppTheme.backgroundSecondary;

                        if (_showExplanation) {
                          if (isCorrect) {
                            borderColor = AppTheme.successGreen;
                            bgColor = AppTheme.successGreen.withValues(alpha: 0.12);
                          } else if (isSelected && !isCorrect) {
                            borderColor = AppTheme.criticalRed;
                            bgColor = AppTheme.criticalRed.withValues(alpha: 0.12);
                          } else {
                            borderColor = AppTheme.borderSubtle;
                            bgColor = AppTheme.backgroundSecondary;
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
                          child: InkWell(
                            onTap: _showExplanation ? null : () => setState(() => _selectedIndex = index),
                            borderRadius: AppTheme.radiusMd,
                            child: Container(
                              padding: const EdgeInsets.all(AppTheme.spacing16),
                              decoration: BoxDecoration(
                                color: bgColor,
                                border: Border.all(color: borderColor, width: isSelected || (_showExplanation && isCorrect) ? 2 : 1),
                                borderRadius: AppTheme.radiusMd,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      question.options[index],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isSelected || (_showExplanation && isCorrect) ? FontWeight.bold : FontWeight.normal,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (_showExplanation && isCorrect)
                                    Icon(LucideIcons.checkCircle2, color: AppTheme.successGreen),
                                  if (_showExplanation && isSelected && !isCorrect)
                                    Icon(LucideIcons.xCircle, color: AppTheme.criticalRed),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      if (_showExplanation) ...[
                        const SizedBox(height: AppTheme.spacing24),
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacing16),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundSecondary,
                            borderRadius: AppTheme.radiusMd,
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('הסבר:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              const SizedBox(height: AppTheme.spacing8),
                              Text(question.explanation, style: TextStyle(color: AppTheme.textSecondary, height: 1.45)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              if (!_showExplanation)
                HopalButton(
                  label: 'בדיקת תשובה',
                  onPressed: _selectedIndex == null ? null : _submitAnswer,
                  icon: LucideIcons.check,
                )
              else
                HopalButton(
                  label: _currentIndex == _sessionQuestions.length - 1 ? 'סיום מבחן' : 'השאלה הבאה',
                  onPressed: _nextQuestion,
                  icon: LucideIcons.arrowLeft,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final percentage = (_score / _sessionQuestions.length * 100).round();
    final isSuccess = percentage >= 75;

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('תוצאות המבחן', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowRight, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSuccess ? LucideIcons.trophy : LucideIcons.bookOpen,
                  size: 80,
                  color: isSuccess ? AppTheme.successGreen : AppTheme.warningAmber,
                ),
                const SizedBox(height: AppTheme.spacing24),
                Text(
                  isSuccess ? 'כל הכבוד! ציון מעולה' : 'יש מקום לשיפור',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: AppTheme.spacing12),
                Text(
                  'ענית נכונה על $_score מתוך ${_sessionQuestions.length} שאלות.',
                  style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
                ),
                if (_earnedPoints > 0) ...[
                  const SizedBox(height: AppTheme.spacing12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.14),
                      borderRadius: AppTheme.radiusPill,
                      border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      '+$_earnedPoints נקודות כשירות נוספו לחשבונך',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.spacing32),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CircularProgressIndicator(
                        value: _score / _sessionQuestions.length,
                        strokeWidth: 12,
                        backgroundColor: AppTheme.backgroundSecondary,
                        valueColor: AlwaysStoppedAnimation<Color>(isSuccess ? AppTheme.successGreen : AppTheme.warningAmber),
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing48),
                HopalButton(
                  label: 'חזרה למרכז הלמידה',
                  onPressed: () => Navigator.pop(context),
                  icon: LucideIcons.arrowRight,
                  variant: HopalButtonVariant.secondary,
                ),
                const SizedBox(height: AppTheme.spacing16),
                HopalButton(
                  label: 'תרגול נוסף',
                  onPressed: _restartQuiz,
                  icon: LucideIcons.rotateCcw,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

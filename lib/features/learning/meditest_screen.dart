import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';

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
  final List<QuizQuestion> _questions = [
    const QuizQuestion(
      question: 'מהו הצעד הראשון בסכמת טיפול בפצוע XCARE בגישת ה-X?',
      options: [
        'פתיחת נתיב אוויר',
        'הנחת חסם עורקים לעצירת דימום פורץ מגפה',
        'מתן חמצן',
        'סריקת גב',
      ],
      correctIndex: 1,
      explanation: 'בשלב X מטפלים קודם כל בדימומים פורצים ומסכני חיים באמצעות חסמי עורקים או לחץ ישיר.',
    ),
    const QuizQuestion(
      question: 'באילו מקרים אסור לתת אופטלגין?',
      options: [
        'כאב ויסרלי (עוויתי)',
        'פצוע עם חום גבוה',
        'רגישות לפול (G6PD חסר)',
        'פצוע לאחר חבלת ראש',
      ],
      correctIndex: 2,
      explanation: 'אופטלגין אסור לאנשים עם חסר באנזים G6PD מחשש להרס כדוריות דם אדומות.',
    ),
    const QuizQuestion(
      question: 'מהו קצב העיסויים הנדרש בהחייאת מבוגר?',
      options: [
        '60-80 לדקה',
        '80-100 לדקה',
        '100-120 לדקה',
        '120-140 לדקה',
      ],
      correctIndex: 2,
      explanation: 'קצב העיסויים המומלץ לפי הנחיות AHA הוא 100-120 עיסויים בדקה.',
    ),
    const QuizQuestion(
      question: 'כמה מ"ג יש במזרק אפיפן צהוב (למבוגר)?',
      options: [
        '0.15 מ"ג',
        '0.3 מ"ג',
        '0.5 מ"ג',
        '1.0 מ"ג',
      ],
      correctIndex: 1,
      explanation: 'מזרק אפיפן צהוב (למבוגר) מכיל 0.3 מ"ג אדרנלין. מזרק ירוק (לילד) מכיל 0.15 מ"ג.',
    ),
    const QuizQuestion(
      question: 'באיזה מיקום נכון להניח חסם עורקים ראשוני בשטח?',
      options: [
        'מעט מעל הפצע',
        'הכי גבוה והכי חזק (High & Tight)',
        'מתחת למפרק הקרוב',
        'על המפרק עצמו',
      ],
      correctIndex: 1,
      explanation: 'בשלב ה-Care Under Fire (הקו הראשון), ההנחיה היא להניח חסם עורקים הכי גבוה והכי חזק על הגפה כדי לעצור דימום מהר.',
    ),
    const QuizQuestion(
      question: 'מהו הטיפול המיידי המתאים להתייבשות קלה (מכת חום/התייבשות)?',
      options: [
        'מתן עירוי של 2 ליטר נוזלים',
        'מנוחה בצל, קירור והחזרת נוזלים בשתייה',
        'מתן תרופות להורדת חום',
        'כיסוי בשמיכת מילוט',
      ],
      correctIndex: 1,
      explanation: 'במקרים של התייבשות קלה ללא הקאות או אובדן הכרה, עדיף להחזיר נוזלים בשתייה יחד עם קירור ומנוחה בצל.',
    ),
    const QuizQuestion(
      question: 'איזה סימן נחשב למאוחר ומעיד על הלם תת-נפחי חמור?',
      options: [
        'דופק מהיר (טכיקרדיה)',
        'ירידה בלחץ הדם (ל"ד נמוך)',
        'עור חיוור וקר',
        'נשימה מהירה',
      ],
      correctIndex: 1,
      explanation: 'ירידה בלחץ הדם היא סימן מאוחר להלם אצל אנשים צעירים ובריאים, ומעידה על איבוד משמעותי מאוד של דם (מעל 30-40%).',
    ),
    const QuizQuestion(
      question: 'מהי מטרת תחבושת אשרמן (Asherman)?',
      options: [
        'עצירת דימום פורץ בגפיים',
        'קיבוע שבר פתוח',
        'אטימת פצע חודר בחזה',
        'חבישת כוויות נרחבות',
      ],
      correctIndex: 2,
      explanation: 'תחבושת אשרמן היא תחבושת אטימה (עם שסתום חד כיווני) המיועדת לפגיעות חזה חודרות כדי למנוע חזה אוויר בלחץ.',
    ),
  ];

  int _currentIndex = 0;
  int? _selectedIndex;
  bool _showExplanation = false;
  int _score = 0;
  bool _quizFinished = false;

  void _submitAnswer() {
    if (_selectedIndex == null) return;
    
    final isCorrect = _selectedIndex == _questions[_currentIndex].correctIndex;
    if (isCorrect) _score++;

    setState(() {
      _showExplanation = true;
    });
  }

  void _nextQuestion() {
    setState(() {
      if (_currentIndex < _questions.length - 1) {
        _currentIndex++;
        _selectedIndex = null;
        _showExplanation = false;
      } else {
        _quizFinished = true;
      }
    });
  }

  void _restartQuiz() {
    setState(() {
      _currentIndex = 0;
      _selectedIndex = null;
      _showExplanation = false;
      _score = 0;
      _quizFinished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_quizFinished) {
      return _buildResultsScreen();
    }

    final question = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Meditest - ריענון חובשים'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16).copyWith(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: (_currentIndex + 1) / _questions.length,
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
                        'שאלה ${_currentIndex + 1} מתוך ${_questions.length}',
                        style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                      Text(
                        question.question,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
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
                            bgColor = AppTheme.successGreen.withValues(alpha: 0.1);
                          } else if (isSelected && !isCorrect) {
                            borderColor = AppTheme.criticalRed;
                            bgColor = AppTheme.criticalRed.withValues(alpha: 0.1);
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
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('הסבר:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              const SizedBox(height: AppTheme.spacing8),
                              Text(question.explanation, style: TextStyle(color: AppTheme.textSecondary, height: 1.4)),
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
                  label: _currentIndex == _questions.length - 1 ? 'סיום מבחן' : 'השאלה הבאה',
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
    final percentage = (_score / _questions.length * 100).round();
    final isSuccess = percentage >= 75;

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('תוצאות המבחן'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                'ענית נכונה על $_score מתוך ${_questions.length} שאלות.',
                style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacing32),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: _score / _questions.length,
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

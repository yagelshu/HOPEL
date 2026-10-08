import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';

class WalkthroughDialog extends StatefulWidget {
  const WalkthroughDialog({super.key});

  @override
  State<WalkthroughDialog> createState() => _WalkthroughDialogState();
}

class _WalkthroughDialogState extends State<WalkthroughDialog> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'ברוך הבא ל-HOPEL!',
      'description': 'האפליקציה נועדה לעזור לך לנהל את הפעילות הרפואית בפלוגה בצורה קלה ומהירה. בוא נעשה סיבוב היכרות קצר.',
      'icon': LucideIcons.shieldCheck,
      'color': AppTheme.primaryGreen,
    },
    {
      'title': 'ניהול פניות רפואיות',
      'description': 'פתח פניות רפואיות לחיילים, הוסף צילומים, תגיות מהירות וקבל המלצות טיפוליות.',
      'icon': LucideIcons.stethoscope,
      'color': AppTheme.warningAmber,
    },
    {
      'title': 'מעקב ציוד וכשירות',
      'description': 'עקוב אחר ציוד חסר בארגז החופ"ל ובערכות החובשים. סרוק ציוד ותעדף השלמות.',
      'icon': LucideIcons.briefcase,
      'color': AppTheme.infoBlue,
    },
    {
      'title': 'לו"ז וסנכרון מלא',
      'description': 'נהל את הלו"ז היומי שלך והסתנכרן בזמן אמת עם שאר צוות הרפואה באפליקציה.',
      'icon': LucideIcons.calendarDays,
      'color': AppTheme.militaryOlive,
    },
  ];

  void _nextPage() {
    if (_currentIndex < _pages.length - 1) {
      setState(() => _currentIndex++);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentIndex];

    return Dialog(
      backgroundColor: AppTheme.backgroundSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing24),
              decoration: BoxDecoration(
                color: (page['color'] as Color).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(page['icon'] as IconData, size: 48, color: page['color'] as Color),
            ),
            const SizedBox(height: AppTheme.spacing24),
            Text(
              page['title'] as String,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              page['description'] as String,
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index ? AppTheme.primaryGreen : AppTheme.borderSubtle,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppTheme.spacing32),
            HopalButton(
              label: _currentIndex == _pages.length - 1 ? 'בוא נתחיל!' : 'הבא',
              onPressed: _nextPage,
              isExpanded: true,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/core/utils/app_constants.dart';
import 'package:chopel_app/features/learning/medication_guide_screen.dart';

class UserManualScreen extends StatelessWidget {
  const UserManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('מדריך למשתמש', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'מבוא למערכת',
              icon: LucideIcons.info,
              content: 'מערכת חופ"ל נועדה לסייע לצוותי הרפואה בניהול השוטף של הפלוגה. המערכת מאפשרת מעקב אחר פניות רפואיות, ניהול ציוד, תרגול מקצועי וסטטוס גזרתי - הכל בזמן אמת ובצורה פשוטה.',
            ),
            _buildSection(
              title: 'מסך הבית (דאשבורד)',
              icon: LucideIcons.layoutDashboard,
              content: 'במסך הבית תוכלו לראות תמונת מצב עדכנית של הגזרה:\n• פניות פתוחות הדורשות טיפול.\n• כשירות הציוד (וסטים וארגזי חופ"ל).\n• רשימת החובשים בכוננות (ניתן ללחוץ לעריכה).\n• הלו"ז היומי המאפשר מעקב אחרי משימות שגרתיות.',
            ),
            _buildSection(
              title: 'ניהול פניות רפואיות',
              icon: LucideIcons.fileText,
              content: 'בלחיצה על "פנייה חדשה", ניתן לפתוח תיק רפואי לחייל.\nיש להזין מספר אישי או שם לחילוץ נתונים, לתאר את התלונה ואף לצרף תמונה במידת הצורך.\nניתן להעביר פניות למצב "טופל" או להשאירן ב"בטיפול / מעקב".',
            ),
            _buildSection(
              title: 'כשירות ציוד',
              icon: LucideIcons.briefcase,
              content: 'ניהול הציוד מתחלק לווסט חובש וארגז חופ"ל.\n• פריטים המסומנים באדום הם פריטים חסרים ויש להשלימם.\n• בלחיצה על פריט ניתן לשנות את הכמות שלו.\n• ניתן לשלוח הודעת חוסרים מרוכזת לחוג"ד בוואטסאפ.\n• כפתור "בדיקת חסם עורקים" מאפשר לוודא את מקוריות החסם באמצעות מספר האצווה (Lot Number).',
            ),
            _buildSection(
              title: 'ידע מקצועי ותרגול',
              icon: LucideIcons.brainCircuit,
              content: '• מדריך תרופות שטח ומחשבון מינונים: מידע קריטי על תרופות, התוויות נגד ו-G6PD.\n• תרגול יומי: מבחני טריוויה המזכים בנקודות כשירות.\nניתן לעקוב אחר ההתקדמות ונקודות הכשירות במסך הפרופיל.',
              action: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  side: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
                  shape: const RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
                ),
                icon: const Icon(LucideIcons.pill, size: 16),
                label: const Text('פתח מדריך תרופות שטח ומחשבון'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MedicationGuideScreen()),
                  );
                },
              ),
            ),
            _buildSection(
              title: 'כלים מתקדמים לשטח ולחימה',
              icon: LucideIcons.radioTower,
              content: '• מכ"ם תחלואה פלוגתי: סורק ברקע את הפניות ומתריע אוטומטית על התפרצויות חריגות (גסטרו, עור, נשימה).\n• דוח חפיפת משמרת: מייצר בלחיצה אחת סיכום צבאי מסודר לוואטסאפ עם כל המקרים הדורשים מעקב והחוסרים.\n• סנכרון שטח P2P: מאפשר להעביר תיקים בין חובשים ב-Bluetooth או קוד מקומי בשטחי לחימה ללא קליטה סלולרית.\n• תזכורות מעקב ומדדים: קביעת בדיקות חום חוזרות, לחץ דם ומנות תרופה עם התרעה בדאשבורד.',
            ),
            _buildSection(
              title: 'ניהול כוננויות ותעסוקה מבצעית',
              icon: LucideIcons.flag,
              content: 'תחת מסך הפרופיל, ניתן לבצע "סיום תעסוקה מבצעית". פעולה זו מאפסת את פניות המרפאה ולוח הזמנים לקראת המעבר לקו הבא, תוך שמירה על המידע בארכיון.',
            ),
            const SizedBox(height: AppTheme.spacing32),
            Center(
              child: Text(
                'גרסה ${AppConstants.version}\nפותח בגאווה עבור צוותי הרפואה בצה"ל',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
            ),
            const SizedBox(height: AppTheme.spacing32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required String content,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryGreen, size: 24),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppTheme.spacing12),
            action,
          ],
        ],
      ),
    );
  }
}

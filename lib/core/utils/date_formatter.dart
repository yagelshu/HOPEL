import 'package:intl/intl.dart';

class DateFormatter {
  static String formatRelative(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'לא צוין תאריך';
    
    final date = DateTime.tryParse(isoString)?.toLocal();
    if (date == null) return 'תאריך לא חוקי';

    final now = DateTime.now();
    final difference = now.difference(date);
    
    // Time formatter (e.g. 14:30)
    final timeFormat = DateFormat('HH:mm');
    final timeString = timeFormat.format(date);

    if (difference.inDays == 0 && now.day == date.day) {
      if (difference.inHours == 0) {
        if (difference.inMinutes <= 1) return 'ממש עכשיו';
        return 'לפני ${difference.inMinutes} דקות';
      }
      if (difference.inHours == 1) return 'לפני שעה';
      if (difference.inHours <= 12) return 'לפני ${difference.inHours} שעות';
      return 'היום, $timeString';
    } else if (difference.inDays == 1 || (difference.inDays == 0 && now.day != date.day)) {
      return 'אתמול, $timeString';
    } else if (difference.inDays > 1 && difference.inDays < 7) {
      return 'לפני ${difference.inDays} ימים';
    } else {
      final dateFormat = DateFormat('dd/MM/yyyy');
      return dateFormat.format(date);
    }
  }

  static String formatShortDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    final date = DateTime.tryParse(isoString)?.toLocal();
    if (date == null) return '';
    
    final dateFormat = DateFormat('dd/MM');
    return dateFormat.format(date);
  }
}

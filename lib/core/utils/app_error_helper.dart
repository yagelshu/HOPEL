import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chopel_app/core/auth/auth_service.dart';

class AppErrorHelper {
  /// Converts any technical exception (Supabase, Postgrest, Network, File) into clean Hebrew.
  static String toHebrew(
    Object error, {
    String fallback = 'אירעה שגיאה מול השרת. בדוק את החיבור ונסה שוב.',
  }) {
    if (error is AuthException) {
      return AuthService.localizeAuthError(error);
    }

    if (error is PostgrestException) {
      final code = (error.code ?? '').toUpperCase();
      final msg = error.message.toLowerCase();

      if (code == '23505' || msg.contains('duplicate key')) {
        if (msg.contains('personal_number') || msg.contains('soldiers')) {
          return 'כבר קיים חייל עם פרטים או מספר אישי זהה במערכת.';
        }
        return 'הנתון כבר קיים במערכת (כפילות רשומה).';
      }
      if (code == '42501' || msg.contains('row-level security') || msg.contains('permission denied')) {
        return 'אין לך הרשאה לביצוע פעולה זו.';
      }
      if (code == '23503' || msg.contains('foreign key')) {
        return 'לא ניתן להשלים את הפעולה מאחר שהפריט מקושר לנתונים אחרים.';
      }
      if (code == 'PGRST116') {
        return 'הרשומה המבוקשת לא נמצאה בשרת.';
      }
      if (code == 'PGRST204' || code == '42703' || code == '42P01') {
        return 'מבנה הנתונים בשרת חסר עדכון (מיגרציית SQL).';
      }

      debugPrint('PostgrestException [$code]: ${error.message}');
      return fallback;
    }

    if (error is FormatException) {
      final msg = error.message.trim();
      final hasHebrew = RegExp(r'[\u0590-\u05FF]').hasMatch(msg);
      if (hasHebrew && msg.isNotEmpty) {
        return msg;
      }
      return 'פורמט הקובץ או הנתונים אינו תקין.';
    }

    final lower = error.toString().toLowerCase();
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('failed to fetch') ||
        lower.contains('clientexception') ||
        lower.contains('xmlhttprequest') ||
        lower.contains('timeout') ||
        lower.contains('network') ||
        lower.contains('connection refused') ||
        lower.contains('os error') ||
        lower.contains('offline')) {
      return 'אין חיבור לאינטרנט. בדוק את הקליטה ונסה שוב.';
    }

    debugPrint('AppErrorHelper unhandled error: $error');
    return fallback;
  }
}


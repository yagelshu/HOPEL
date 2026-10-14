import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Decides whether a failed server call should be retried later (no reception)
/// or was rejected by the server (bad data / permissions) and needs attention.
bool isNetworkError(Object e) {
  if (e is TimeoutException) return true;
  if (e is PostgrestException) {
    final code = e.code ?? '';
    // JWT expired / auth refresh in progress -> retry later
    if (code == 'PGRST301' || code == 'PGRST303') return true;
    if (code.isNotEmpty) return false;
  }
  if (e is AuthRetryableFetchException) return true;
  final s = e.toString();
  const markers = [
    'SocketException',
    'Failed host lookup',
    'ClientException',
    'Connection refused',
    'Connection reset',
    'Connection closed',
    'Network is unreachable',
    'XMLHttpRequest error',
    'Failed to fetch',
    'HandshakeException',
  ];
  return markers.any(s.contains);
}

/// Human-readable Hebrew message for a server rejection.
String describeServerError(Object e) {
  if (e is PostgrestException) {
    switch (e.code) {
      case '23505':
        return 'כבר קיימת רשומה זהה (למשל מספר אישי כפול)';
      case '23503':
        return 'הרשומה מפנה לנתון שלא קיים בשרת (למשל חייל שנמחק)';
      case '42501':
        return 'אין הרשאה לפעולה הזו - ודא שאתה משויך לפלוגה';
      case '42703':
      case 'PGRST204':
        return 'מסד הנתונים לא מעודכן - יש להריץ את supabase/schema.sql';
    }
    return e.message;
  }
  return e.toString();
}

/// Thrown to the UI when the server rejected a save made while online.
class SaveRejected implements Exception {
  final String message;
  SaveRejected(this.message);
  @override
  String toString() => message;
}
